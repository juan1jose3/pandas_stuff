import requests
import json

url = "https://pokeapi.co/api/v2/pokemon?limit=100"
response = requests.get(url).json()
print(json.dumps(response,ensure_ascii=False))

