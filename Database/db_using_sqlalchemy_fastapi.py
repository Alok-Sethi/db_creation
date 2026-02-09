from typing import List
from pydantic import BaseModel
from fastapi import FastAPI, requests, HTTPException, Depends
from sqlalchemy import Column, Integer, String, create_engine
from sqlalchemy.orm import sessionmaker, declarative_base, Session


# Database Configuration
DATABASE_URL = "sqlite:///employee.db"
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


# Create a table
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String, nullable=False)
    email = Column(String, nullable=False, unique=False, index=True)
    password = Column(String, nullable=False)

Base.metadata.create_all(bind=engine)

# pydantic schema
class UserCreate(BaseModel):
    name: str
    email: str
    password: str

class UserRead(BaseModel):
    id: int
    name: str
    email: str
    password: str

    class Config:
        orm_mode = True

# fastapi app and DB dependencies
app = FastAPI()

def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# API endpoint
# POST: Create a user equivalent to insert statement
@app.post("/users", response_model=UserRead)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = User(name=user.name, email=user.email, password=user.password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# GET: List all users
@app.get("/users", response_model=List[UserRead])
def read_users(db: Session = Depends(get_db)):
    users = db.query(User).all()
    return users

# GET: Get a single user by id
@app.get("/users/{user_id}", response_model=UserRead)
def read_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# remove duplicates from table
@app.delete("/users/remove-duplicates", response_model=List[UserRead])
def remove_duplicates(db: Session = Depends(get_db)):
    db.query(User).filter(User.id != User.id).delete()
    db.commit()
    return db.query(User).all()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)








