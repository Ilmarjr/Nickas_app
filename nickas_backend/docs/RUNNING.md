py# How to Run the Nickas Backend

This is the backend service for the Nickas application, built with FastAPI.

## Prerequisites

- [Python](https://www.python.org/downloads/) (3.8 or higher)
- pip (Python package installer)

## Setup

1. **Navigate to the backend directory:**
   ```bash
   cd nickas_backend
   ```

2. **Create a virtual environment:**
   ```bash
   # Windows
   python -m venv venv
   
   # macOS/Linux
   python3 -m venv venv
   ```

3. **Activate the virtual environment:**
   ```bash
   # Windows
   .\venv\Scripts\activate
   
   # macOS/Linux
   source venv/bin/activate
   ```

4. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

## Running the Server

Start the application using `uvicorn`:

```bash
uvicorn main:app --reload
```

The server will start at `http://127.0.0.1:8000`.

## API Documentation

Once the server is running, you can access the interactive API documentation at:

- Swagger UI: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- ReDoc: [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)
