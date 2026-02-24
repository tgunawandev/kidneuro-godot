"""Game catalog endpoints."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from kidneuro.database import get_db
from kidneuro.middleware.auth import get_current_user, require_role
from kidneuro.models.game import Game, GameCategory
from kidneuro.models.user import User, UserRole

router = APIRouter()


class GameResponse(Game.__class__):
    pass


from pydantic import BaseModel


class GameOut(BaseModel):
    id: uuid.UUID
    slug: str
    title: str
    description: str
    category: GameCategory
    min_age: int
    max_age: int
    version: str
    thumbnail_url: str | None
    html5_url: str | None
    therapy_goals: dict | None
    is_active: bool
    is_premium: bool

    model_config = {"from_attributes": True}


class GameListOut(BaseModel):
    items: list[GameOut]
    total: int


class GameCreate(BaseModel):
    slug: str
    title: str
    description: str
    category: GameCategory
    min_age: int = 3
    max_age: int = 12
    godot_scene: str
    thumbnail_url: str | None = None
    html5_url: str | None = None
    therapy_goals: dict | None = None
    config_schema: dict | None = None
    is_premium: bool = False


@router.get("", response_model=GameListOut)
async def list_games(
    category: GameCategory | None = None,
    age: int | None = Query(None, ge=1, le=18),
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    query = select(Game).where(Game.is_active.is_(True)).order_by(Game.sort_order, Game.title)
    if category:
        query = query.where(Game.category == category)
    if age:
        query = query.where(Game.min_age <= age, Game.max_age >= age)

    result = await db.execute(query)
    games = list(result.scalars().all())
    return {"items": games, "total": len(games)}


@router.get("/{game_id}", response_model=GameOut)
async def get_game(
    game_id: uuid.UUID,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Game:
    result = await db.execute(select(Game).where(Game.id == game_id))
    game = result.scalar_one_or_none()
    if not game:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Game not found")
    return game


@router.post("", response_model=GameOut, status_code=status.HTTP_201_CREATED)
async def create_game(
    payload: GameCreate,
    _admin: User = Depends(require_role(UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db),
) -> Game:
    game = Game(**payload.model_dump())
    db.add(game)
    await db.flush()
    await db.refresh(game)
    return game
