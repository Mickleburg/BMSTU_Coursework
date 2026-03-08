// frontend/src/blocks/message-list/message-list.js

import { getMessages } from '../../scripts/api.js';

// Функция для отрисовки одного сообщения в DOM.
export function renderMessage(message) {
  console.log('Отрисовка сообщения:', message);

  const listEl = document.getElementById('messagesList');
  if (!listEl) {
    console.error('Элемент messagesList не найден в DOM');
    return;
  }

  const itemEl = document.createElement('div');
  itemEl.className = 'message-item';
  itemEl.innerHTML = `
    <div class="message-header">
      <span class="message-author">${message.author?.username || 'Anonymous'}</span>
      <span class="message-date">${new Date(message.created_at).toLocaleString()}</span>
    </div>
    <div class="message-content">${message.content}</div>
  `;
  listEl.appendChild(itemEl);
}

// Загрузка и отображение списка сообщений для темы
export async function loadMessages(topicId) {
  console.log('API: Получение сообщений для темы:', topicId);
  try {
    const response = await getMessages(topicId);
    const messages = response.data;
    
    if (!Array.isArray(messages)) {
      console.error('API: Ожидался массив сообщений, но получил:', messages);
      return;
    }

    const listEl = document.getElementById('messagesList');
    if (listEl) {
      listEl.innerHTML = '';
    }

    messages.forEach(renderMessage);
  } catch (err) {
    console.error('Ошибка загрузки сообщений:', err);
  }
}
