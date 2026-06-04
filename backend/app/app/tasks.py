from app.celery_app import celery_app


@celery_app.task
def placeholder_task():
    """Phase 2.1+ 비동기 작업 플레이스홀더."""
    return "ok"
