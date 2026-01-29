from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from typing import List

import models, schemas
from database import SessionLocal, engine
from auth import create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES
from datetime import timedelta
import jwt
from auth import SECRET_KEY, ALGORITHM

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Nickas Backend")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Auth Utilities
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

# Auth Dependency
async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        token_data = schemas.TokenData(email=email)
    except jwt.PyJWTError:
        raise credentials_exception
    user = get_user_by_email(db, email=token_data.email)
    if user is None:
        raise credentials_exception
    return user

import re

# ... existing code ...

@app.post("/register", response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    # 1. Validate Email
    email_regex = r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$"
    if not re.match(email_regex, user.email):
         raise HTTPException(status_code=400, detail="Invalid email format")

    # 2. Validate Password Length
    if len(user.password) < 8:
         raise HTTPException(status_code=400, detail="Password must be at least 8 characters long")

    # 3. Check for existing email
    db_user = get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # 4. Check for existing username
    db_username = db.query(models.User).filter(models.User.username == user.username).first()
    if db_username:
        raise HTTPException(status_code=400, detail="Username already taken")

    hashed_password = get_password_hash(user.password)
    db_user = models.User(
        email=user.email,
        hashed_password=hashed_password,
        username=user.username,
        date_of_birth=user.date_of_birth
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.post("/token", response_model=schemas.Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    # OAuth2PasswordRequestForm expects "username" field, so we map email to username
    user = get_user_by_email(db, email=form_data.username)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/")
def read_root():
    return {"message": "Welcome to Nickas Backend"}

@app.get("/users/me", response_model=schemas.User)
async def read_users_me(current_user: models.User = Depends(get_current_user)):
    return current_user

# --- Shopping Lists ---

@app.get("/lists/", response_model=List[schemas.ShoppingList])
def read_lists(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    lists = db.query(models.ShoppingList).filter(models.ShoppingList.owner_id == current_user.id).offset(skip).limit(limit).all()
    return lists

@app.post("/lists/", response_model=schemas.ShoppingList)
def create_list(list_in: schemas.ShoppingListCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # Check if list with same ID already exists (sync scenario)
    db_list = db.query(models.ShoppingList).filter(models.ShoppingList.id == list_in.id).first()
    if db_list:
         # Update logical if needed, or ignore
         # For simplicity in MVP, if exists we return it or update name
         db_list.name = list_in.name
         db_list.date = list_in.date
         db.commit()
         db.refresh(db_list)
         return db_list
    
    db_list = models.ShoppingList(**list_in.dict(), owner_id=current_user.id)
    db.add(db_list)
    db.commit()
    db.refresh(db_list)
    return db_list

@app.delete("/lists/{list_id}")
def delete_list(list_id: str, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    db_list = db.query(models.ShoppingList).filter(models.ShoppingList.id == list_id, models.ShoppingList.owner_id == current_user.id).first()
    if not db_list:
        raise HTTPException(status_code=404, detail="List not found")
    db.delete(db_list)
    db.commit()
    return {"ok": True}

# --- Items ---

@app.post("/items/", response_model=schemas.Item)
def create_item(item_in: schemas.ItemCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # Verify strict ownership of list
    parent_list = db.query(models.ShoppingList).filter(models.ShoppingList.id == item_in.list_id, models.ShoppingList.owner_id == current_user.id).first()
    if not parent_list:
         raise HTTPException(status_code=404, detail="List not found")

    db_item = db.query(models.Item).filter(models.Item.id == item_in.id).first()
    if db_item:
        # Update
        for key, value in item_in.dict().items():
            setattr(db_item, key, value)
        db.commit()
        db.refresh(db_item)
        return db_item

    db_item = models.Item(**item_in.dict())
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

@app.put("/items/{item_id}", response_model=schemas.Item)
def update_item(item_id: str, item_in: schemas.ItemBase, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # Needed to join to check ownership
    db_item = db.query(models.Item).join(models.ShoppingList).filter(
        models.Item.id == item_id,
        models.ShoppingList.owner_id == current_user.id
    ).first()
    
    if not db_item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    for key, value in item_in.dict().items():
        setattr(db_item, key, value)
    
    db.commit()
    db.refresh(db_item)
    return db_item

@app.delete("/items/{item_id}")
def delete_item(item_id: str, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
     db_item = db.query(models.Item).join(models.ShoppingList).filter(
        models.Item.id == item_id,
        models.ShoppingList.owner_id == current_user.id
    ).first()
     if not db_item:
        raise HTTPException(status_code=404, detail="Item not found")
     
     db.delete(db_item)
     db.commit()
     return {"ok": True}

