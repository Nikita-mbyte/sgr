#!/bin/bash

set -e

# Локальные образы для тюнинга
LOCAL_IMAGES=(
localhost/sgr-agent-core:latest
)

# Удаленный репозиторий для push
REMOTE_REPO=nexus.isb/genai-nonprod-docker-hosted
INTERNAL_VERSION=obru

echo "INFO: Local images to tune: ${LOCAL_IMAGES[@]}"

echo "INFO: Tune images (tag suffix -tuned on output)"
for i in ${LOCAL_IMAGES[@]}; do
    curl https://bitbucket.isb/projects/IT4IT/repos/docker-image-tuner/raw/build.sh | \
    bash -s -- ${i} --no-pull -t tuned
done

echo "INFO: Build Dockerfile using tuned image and set remote tag (tag suffix -obru on output)"
for i in ${LOCAL_IMAGES[@]}; do
    # Извлекаем имя образа без localhost/ префикса
    IMAGE_NAME=$(echo ${i} | sed 's|localhost/||')
    # Создаем образ с удаленным тегом
    docker build --build-arg IMG=${i}-tuned --tag ${REMOTE_REPO}/${IMAGE_NAME}-${INTERNAL_VERSION} .
done

echo "INFO: Push images to remote repository"
for i in ${LOCAL_IMAGES[@]}; do
    IMAGE_NAME=$(echo ${i} | sed 's|localhost/||')
    docker push ${REMOTE_REPO}/${IMAGE_NAME}-${INTERNAL_VERSION}
done

echo "INFO: List pushed images"
for i in ${LOCAL_IMAGES[@]}; do
    IMAGE_NAME=$(echo ${i} | sed 's|localhost/||')
    echo ${REMOTE_REPO}/${IMAGE_NAME}-${INTERNAL_VERSION}
done