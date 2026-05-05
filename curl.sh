curl http://127.0.0.1:8000/v1/completions \
    -H "Content-Type: application/json" \
    -d '{
        "model": "/workspace/Meta-Llama-3-8B-Instruct/",
        "prompt": "请用中文思考和回答：A paper punch can be placed at any point in the plane, and when it operates, it can punch out points at an irrational distance from it. What is the minimum number of paper punches needed to punch out all points in the plane?",
        "max_tokens": 1000,
        "temperature": 0
    }'
