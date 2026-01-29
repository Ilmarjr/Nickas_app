from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime
from sqlalchemy.orm import relationship
from database import Base
import datetime

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    username = Column(String, unique=True, index=True)
    date_of_birth = Column(DateTime)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)

    lists = relationship("ShoppingList", back_populates="owner")

class ShoppingList(Base):
    __tablename__ = "shopping_lists"

    id = Column(String, primary_key=True, index=True) # UUID from frontend
    name = Column(String)
    date = Column(DateTime, default=datetime.datetime.utcnow)
    owner_id = Column(Integer, ForeignKey("users.id"))

    owner = relationship("User", back_populates="lists")
    items = relationship("Item", back_populates="shopping_list", cascade="all, delete-orphan")

class Item(Base):
    __tablename__ = "items"

    id = Column(String, primary_key=True, index=True) # UUID from frontend
    list_id = Column(String, ForeignKey("shopping_lists.id"))
    name = Column(String)
    brand = Column(String, default="")
    quantity = Column(Float, default=1.0)
    price = Column(Float, default=0.0)
    is_checked = Column(Boolean, default=False)
    
    shopping_list = relationship("ShoppingList", back_populates="items")
