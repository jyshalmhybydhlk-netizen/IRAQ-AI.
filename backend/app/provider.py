import httpx
from .config import settings
class ProviderError(RuntimeError):pass
SYSTEM='أنت ذكاء العراق، مساعد عربي دقيق ومفيد. أجب بوضوح ولا تختلق معلومات.'
async def answer(messages):
 provider=settings.ai_provider.lower()
 if provider=='ollama':
  url=settings.ollama_url.rstrip('/')+'/api/chat'; payload={'model':settings.ollama_model,'messages':[{'role':'system','content':SYSTEM},*messages],'stream':False}; headers={}
 elif provider in ('openai','openai_compatible'):
  if not settings.openai_api_key: raise ProviderError('مفتاح المزود السحابي غير مضبوط على الخادم')
  url=settings.openai_base_url.rstrip('/')+'/chat/completions'; payload={'model':settings.openai_model,'messages':[{'role':'system','content':SYSTEM},*messages]}; headers={'Authorization':f'Bearer {settings.openai_api_key}'}
 else: raise ProviderError('AI_PROVIDER يجب أن يكون ollama أو openai_compatible')
 try:
  async with httpx.AsyncClient(timeout=180) as c: r=await c.post(url,json=payload,headers=headers); r.raise_for_status(); data=r.json()
  text=data.get('message',{}).get('content','') if provider=='ollama' else data['choices'][0]['message']['content']
  if not isinstance(text,str) or not text.strip(): raise ProviderError('النموذج أعاد إجابة فارغة')
  return text
 except ProviderError: raise
 except (httpx.HTTPError,ValueError,KeyError,IndexError,TypeError) as e: raise ProviderError(f'فشل الاتصال بالنموذج: {e}') from e
