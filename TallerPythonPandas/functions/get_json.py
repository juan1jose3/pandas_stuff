import requests
import json

url = "https://restcountries.com/v3.1/all?fields=name,capital,currencies"
response = requests.get(url).json()
print(json.dumps(response,ensure_ascii=False))