import { getTopics } from '../../../scripts/api.js';

export async function loadTopics() {
    const container = document.getElementById('topicsList');
    if (!container) {
        console.error('Контейнер для тем не найден!');
        return;
    }

    console.log('Загружаем темы...');
    
    // Показываем индикатор загрузки
    container.innerHTML = '<div class="loading">Загрузка тем...</div>';
    
    try {
        console.log('Отправляем запрос на получение тем...');
        const response = await getTopics();
        console.log('Получены темы:', response);
        // Извлекаем массив тем из ответа API
        const topics = response.data || response;
        renderTopics(topics);
    } catch (error) {
        console.error('Ошибка загрузки тем:', error);
        container.innerHTML = '<div class="error">Ошибка загрузки тем: ' + error.message + '</div>';
    }
}

function renderTopics(topics) {
    const container = document.getElementById('topicsList');
    if (!container) return;

    if (!topics || topics.length === 0) {
        container.innerHTML = '<div class="empty">Темы пока не созданы</div>';
        return;
    }

    container.innerHTML = '';

    topics.forEach(topic => {
        const topicElement = document.createElement('div');
        topicElement.className = 'topic-card';
        topicElement.innerHTML = `
            <h3 class="topic-card__title">${topic.title}</h3>
            <p class="topic-card__description">${topic.rules || 'Правила не указаны'}</p>
            <a href="topic.html?id=${topic.id}" class="button topic-card__link">Перейти</a>
        `;
        container.appendChild(topicElement);
    });
}