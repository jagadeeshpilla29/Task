from bson import ObjectId


def object_id(value: str) -> ObjectId:
    if not ObjectId.is_valid(value):
        raise ValueError("Invalid object id")
    return ObjectId(value)


def serialize_id(document: dict) -> dict:
    document["id"] = str(document.pop("_id"))
    return document
