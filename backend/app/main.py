from uuid import uuid4
from fastapi import FastAPI,Depends,HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel,Field
from sqlalchemy.orm import Session,selectinload
from sqlalchemy import select
from .db import Base,engine,SessionLocal,get_db
from .models import Conversation,Message
from .provider import answer,ProviderError
from .config import settings
Base.metadata.create_all(engine)
app=FastAPI(title='IRAQ AI API',version='1.0.0')
origins=[x.strip() for x in settings.cors_origins.split(',') if x.strip()]
app.add_middleware(CORSMiddleware,allow_origins=origins,allow_methods=['*'],allow_headers=['*'])
class ChatIn(BaseModel): message:str=Field(min_length=1,max_length=12000); conversation_id:str|None=None
class ChatOut(BaseModel): answer:str; conversation_id:str
@app.get('/health')
def health(): return {'status':'ok','service':'IRAQ AI'}
@app.get('/ready')
def ready():
 try:
  with SessionLocal() as db: db.execute(select(1))
  return {'ready':True,'provider':settings.ai_provider}
 except Exception as e: raise HTTPException(503,'database unavailable') from e
@app.post('/api/v1/chat',response_model=ChatOut)
async def chat(body:ChatIn,db:Session=Depends(get_db)):
 text=body.message.strip()
 if not text: raise HTTPException(422,'الرسالة فارغة')
 conv=db.scalar(select(Conversation).options(selectinload(Conversation.messages)).where(Conversation.id==body.conversation_id)) if body.conversation_id else None
 if body.conversation_id and conv is None: raise HTTPException(404,'المحادثة غير موجودة')
 if conv is None: conv=Conversation(id=str(uuid4())); db.add(conv); db.flush()
 history=[{'role':m.role,'content':m.content} for m in conv.messages if m.role in ('user','assistant')][-12:]
 history.append({'role':'user','content':text})
 try: result=await answer(history)
 except ProviderError as e: db.rollback(); raise HTTPException(503,str(e)) from e
 db.add_all([Message(conversation_id=conv.id,role='user',content=text),Message(conversation_id=conv.id,role='assistant',content=result)]); db.commit()
 return {'answer':result,'conversation_id':conv.id}
@app.get('/api/v1/conversations/{cid}')
def history(cid:str,db:Session=Depends(get_db)):
 conv=db.scalar(select(Conversation).options(selectinload(Conversation.messages)).where(Conversation.id==cid))
 if not conv: raise HTTPException(404,'المحادثة غير موجودة')
 return {'conversation_id':cid,'messages':[{'role':m.role,'content':m.content} for m in conv.messages]}
