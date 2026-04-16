import time

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from app.api import auth, products
from app.core.config import get_settings
from app.core.database import create_indexes

settings = get_settings()
settings.upload_dir.mkdir(parents=True, exist_ok=True)
app = FastAPI(title=settings.app_name)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory=str(settings.upload_dir)), name="uploads")
app.include_router(auth.router, prefix=settings.api_prefix)
app.include_router(products.router, prefix=settings.api_prefix)


@app.middleware("http")
async def request_logger(request: Request, call_next):
    started = time.perf_counter()
    print(f"[API] -> {request.method} {request.url.path}")
    response = await call_next(request)
    elapsed_ms = (time.perf_counter() - started) * 1000
    print(f"[API] <- {request.method} {request.url.path} {response.status_code} {elapsed_ms:.1f}ms")
    return response


@app.on_event("startup")
async def startup() -> None:
    settings.upload_dir.mkdir(parents=True, exist_ok=True)
    await create_indexes()


@app.exception_handler(RequestValidationError)
async def validation_handler(_: Request, exc: RequestValidationError) -> JSONResponse:
    return JSONResponse(
        status_code=400,
        content=jsonable_encoder(
            {"success": False, "message": "Validation error", "errors": exc.errors()}
        ),
    )


@app.exception_handler(HTTPException)
async def http_handler(_: Request, exc: HTTPException) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={"success": False, "message": exc.detail},
        headers=exc.headers,
    )


@app.exception_handler(Exception)
async def generic_handler(_: Request, exc: Exception) -> JSONResponse:
    return JSONResponse(status_code=500, content={"success": False, "message": "Internal server error"})


@app.get("/health")
async def health() -> dict:
    return {"success": True, "message": "ok"}
