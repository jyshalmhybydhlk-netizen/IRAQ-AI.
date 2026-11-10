from datetime import datetime,timezone
from sqlalchemy import String,Text,DateTime,ForeignKey
from sqlalchemy.orm import Mapped,mapped_column,relationship
from .db import Base
class Conversation(Base):
 __tablename__='conversations'
 id:Mapped[str]=mapped_column(String(36),primary_key=True)
 messages:Mapped[list['Message']]=relationship(back_populates='conversation',cascade='all, delete-orphan',order_by='Message.id')
class Message(Base):
 __tablename__='messages'
 id:Mapped[int]=mapped_column(primary_key=True,autoincrement=True)
 conversation_id:Mapped[str]=mapped_column(ForeignKey('conversations.id'),index=True)
 role:Mapped[str]=mapped_column(String(20)); content:Mapped[str]=mapped_column(Text)
 created_at:Mapped[datetime]=mapped_column(DateTime,default=lambda:datetime.now(timezone.utc))
 conversation:Mapped[Conversation]=relationship(back_populates='messages')
