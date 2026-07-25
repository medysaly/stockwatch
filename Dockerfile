FROM ghcr.io/astral-sh/uv:0.11.32 AS uv

FROM public.ecr.aws/lambda/python:3.12-arm64 AS builder

ENV UV_COMPILE_BYTECODE=1
ENV UV_NO_INSTALLER_METADATA=1
ENV UV_LINK_MODE=copy

RUN --mount=from=uv,source=/uv,target=/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv export --frozen --no-dev --no-editable -o requirements.txt && \
    uv pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}" --only-binary=:all:

FROM public.ecr.aws/lambda/python:3.12-arm64

COPY --from=builder ${LAMBDA_TASK_ROOT} ${LAMBDA_TASK_ROOT}
COPY main.py ${LAMBDA_TASK_ROOT}

CMD ["main.handler"]
