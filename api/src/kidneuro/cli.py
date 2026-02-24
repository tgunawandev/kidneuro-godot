"""KidNeuro CLI - management commands."""

import typer
from rich.console import Console
from rich.table import Table

app = typer.Typer(name="kidneuro", help="KidNeuro Management CLI")
console = Console()


@app.command()
def version():
    """Show version."""
    from kidneuro import __version__
    console.print(f"KidNeuro API v{__version__}")


@app.command()
def seed():
    """Seed database with sample data."""
    import asyncio
    from kidneuro.services.seed import seed_database
    asyncio.run(seed_database())
    console.print("[green]Database seeded successfully[/green]")


@app.command()
def create_admin(
    email: str = typer.Option(..., prompt=True),
    password: str = typer.Option(..., prompt=True, hide_input=True),
    name: str = typer.Option(..., prompt=True),
):
    """Create admin user."""
    import asyncio
    from kidneuro.services.seed import create_admin_user
    asyncio.run(create_admin_user(email, password, name))
    console.print(f"[green]Admin user {email} created[/green]")


@app.command()
def routes():
    """List all API routes."""
    from kidneuro.main import app as fastapi_app

    table = Table(title="API Routes")
    table.add_column("Method", style="cyan")
    table.add_column("Path", style="green")
    table.add_column("Name", style="yellow")

    for route in fastapi_app.routes:
        if hasattr(route, "methods"):
            for method in route.methods:
                table.add_row(method, route.path, route.name or "")

    console.print(table)


@app.command()
def check():
    """Run health checks."""
    import asyncio
    from sqlalchemy import text
    from kidneuro.database import engine

    async def _check():
        try:
            async with engine.begin() as conn:
                await conn.execute(text("SELECT 1"))
            console.print("[green]Database: OK[/green]")
        except Exception as e:
            console.print(f"[red]Database: FAIL - {e}[/red]")

    asyncio.run(_check())


if __name__ == "__main__":
    app()
