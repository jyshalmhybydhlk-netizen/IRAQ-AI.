from pydantic_settings import BaseSettings, SettingsConfigDict
class Settings(BaseSettings):
    ai_provider:str='ollama'; database_url:str='sqlite:///./iraq_ai.db'
    ollama_url:str='http://127.0.0.1:11434'; ollama_model:str='qwen2.5:3b'
    openai_base_url:str='https://api.openai.com/v1'; openai_api_key:str=''; openai_model:str='gpt-4o-mini'
    cors_origins:str='*'
    model_config=SettingsConfigDict(env_file='.env',extra='ignore')
settings=Settings()
