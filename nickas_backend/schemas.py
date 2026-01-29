from typing import Optional, List
from pydantic import BaseModel
from datetime import datetime

class ItemBase(BaseModel):
    name: str
    brand: Optional[str] = ""
    quantity: float = 1.0
    price: float = 0.0
    is_checked: bool = False

class ItemCreate(ItemBase):
    id: str # UUID provided by frontend
    list_id: str

class Item(ItemBase):
    id: str
    list_id: str

    class Config:
        orm_mode = True

class ShoppingListBase(BaseModel):
    name: str
    date: datetime

class ShoppingListCreate(ShoppingListBase):
    id: str # UUID provided by frontend

class ShoppingList(ShoppingListBase):
    id: str
    owner_id: int
    items: List[Item] = []

    class Config:
        orm_mode = True

class UserBase(BaseModel):
    email: str
    username: str

class UserCreate(UserBase):
    password: str
    date_of_birth: datetime

class User(UserBase):
    id: int
    is_active: bool
    date_of_birth: Optional[datetime] = None
    lists: List[ShoppingList] = []

    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None
