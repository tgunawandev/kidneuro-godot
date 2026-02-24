"""Children management endpoints."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from kidneuro.database import get_db
from kidneuro.middleware.auth import get_current_user
from kidneuro.models.child import Child
from kidneuro.models.user import User, UserRole
from kidneuro.schemas.child import ChildCreate, ChildListResponse, ChildResponse, ChildUpdate

router = APIRouter()


@router.get("", response_model=ChildListResponse)
async def list_children(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    query = select(Child)
    if current_user.role == UserRole.PARENT:
        query = query.where(Child.parent_id == current_user.id)
    result = await db.execute(query.order_by(Child.first_name))
    children = list(result.scalars().all())
    return {"items": children, "total": len(children)}


@router.post("", response_model=ChildResponse, status_code=status.HTTP_201_CREATED)
async def create_child(
    payload: ChildCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Child:
    child = Child(parent_id=current_user.id, **payload.model_dump())
    db.add(child)
    await db.flush()
    await db.refresh(child)
    return child


@router.get("/{child_id}", response_model=ChildResponse)
async def get_child(
    child_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Child:
    result = await db.execute(select(Child).where(Child.id == child_id))
    child = result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Child not found")
    if current_user.role == UserRole.PARENT and child.parent_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
    return child


@router.patch("/{child_id}", response_model=ChildResponse)
async def update_child(
    child_id: uuid.UUID,
    payload: ChildUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Child:
    result = await db.execute(select(Child).where(Child.id == child_id))
    child = result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Child not found")
    if current_user.role == UserRole.PARENT and child.parent_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(child, field, value)

    await db.flush()
    await db.refresh(child)
    return child


@router.delete("/{child_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_child(
    child_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    result = await db.execute(select(Child).where(Child.id == child_id))
    child = result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Child not found")
    if current_user.role == UserRole.PARENT and child.parent_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
    await db.delete(child)
