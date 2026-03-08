import { getTopic } from '../scripts/api.js';
import { initMessageForm } from '../blocks/message-form/message-form.js';
import { loadMessages } from '../blocks/message-list/message-list.js';
import { renderMessage } from '../blocks/message-list/message-list.js';
import { initReplyManager } from '../blocks/reply-manager/reply-manager.js';

let currentTopicId = null;

// Конфигурация уровней логирования
const LOG_LEVELS = {
  DEBUG: 'DEBUG',
  INFO: 'INFO',
  WARN: 'WARN',
  ERROR: 'ERROR'
};

// Функция логирования
function log(level, message, data = null) {
  const timestamp = new Date().toISOString();
  const logMessage = `[${timestamp}] [${level}] ${message}`;
  
  switch (level) {
    case LOG_LEVELS.DEBUG:
      console.debug(logMessage, data || '');
      break;
    case LOG_LEVELS.INFO:
      console.info(logMessage, data || '');
      break;
    case LOG_LEVELS.WARN:
      console.warn(logMessage, data || '');
      break;
    case LOG_LEVELS.ERROR:
      console.error(logMessage, data || '');
      break;
    default:
      console.log(logMessage, data || '');
  }
}

document.addEventListener('renderMessage', (event) => {
  const message = event.detail;
  renderMessage(message);
});

document.addEventListener('DOMContentLoaded', () => {
  log(LOG_LEVELS.INFO, 'Загрузка страницы темы начата');
  
  const urlParams = new URLSearchParams(window.location.search);
  const topicId = urlParams.get('id');
  
  log(LOG_LEVELS.DEBUG, 'Параметры URL', { topicId });

  if (!topicId) {
    log(LOG_LEVELS.ERROR, 'ID темы не указан в параметрах URL');
    alert('Тема не найдена!');
    window.location.href = 'index.html';
    return;
  }

  log(LOG_LEVELS.INFO, 'Загрузка данных темы', { topicId });
  
  getTopic(topicId)
    .then(response => {
        // Добавляем проверку структуры ответа
        console.log("Полный ответ от API:", response);
        
        // Проверяем разные возможные структуры ответа
        let topicData, messagesData;
        
        if (response && response.data) {
            // Если ответ обернут в data (стандартный случай)
            topicData = response.data.topic;
            messagesData = response.data.messages;
        } else if (response && response.topic) {
            // Если ответ приходит напрямую (старая структура)
            topicData = response.topic;
            messagesData = response.messages;
        } else {
            throw new Error('Неверная структура ответа от сервера');
        }

        log(LOG_LEVELS.INFO, 'Данные темы успешно получены', { 
            topic: topicData, 
            messagesCount: messagesData?.length || 0 
        });

        const topic = topicData;
        const messages = messagesData;

        console.log("Тема:", topic);
        console.log("Сообщения:", messages);

        const topicTitleEl = document.getElementById('topicTitle');
        const topicRulesEl = document.getElementById('topicRules');

        if (topicTitleEl) {
            if (topic && topic.title) {
                topicTitleEl.textContent = topic.title;
                log(LOG_LEVELS.DEBUG, 'Заголовок темы установлен', { title: topic.title });
            } else {
                log(LOG_LEVELS.ERROR, 'Заголовок темы отсутствует в ответе');
                topicTitleEl.textContent = 'Неизвестная тема';
            }
        }

        if (topicRulesEl) {
            if (topic && topic.rules) {
                topicRulesEl.textContent = topic.rules;
                log(LOG_LEVELS.DEBUG, 'Правила темы установлены', { rules: topic.rules });
            } else {
                topicRulesEl.textContent = 'Правила не указаны';
                log(LOG_LEVELS.WARN, 'Правила темы отсутствуют');
            }
        }

        // Отрисовка сообщений
        const listEl = document.getElementById('messagesList');
        if (Array.isArray(messages) && listEl) {
            log(LOG_LEVELS.INFO, 'Начало отрисовки сообщений', { count: messages.length });
            
            listEl.innerHTML = '';
            messages.forEach((msg, index) => {
                const event = new CustomEvent('renderMessage', { detail: msg });
                document.dispatchEvent(event);
                log(LOG_LEVELS.DEBUG, `Сообщение ${index + 1} отправлено на отрисовку`, { 
                    messageId: msg.id,
                    author: msg.author 
                });
            });
            
            log(LOG_LEVELS.INFO, 'Все сообщения отправлены на отрисовку');
        } else {
            if (!listEl) {
                log(LOG_LEVELS.ERROR, 'Элемент списка сообщений не найден');
            }
            if (!Array.isArray(messages)) {
                log(LOG_LEVELS.ERROR, 'Сообщения не являются массивом', { messages });
                // Очищаем список, если сообщений нет
                if (listEl) listEl.innerHTML = '<p>Сообщений пока нет</p>';
            }
        }
    })
    .catch(error => {
        log(LOG_LEVELS.ERROR, 'Ошибка загрузки темы', { 
            error: error.message, 
            topicId,
            stack: error.stack 
        });
        console.error('Ошибка загрузки темы:', error);
        alert('Не удалось загрузить тему');
        
        // Устанавливаем заглушки на случай ошибки
        const topicTitleEl = document.getElementById('topicTitle');
        const topicRulesEl = document.getElementById('topicRules');
        const listEl = document.getElementById('messagesList');
        
        if (topicTitleEl) topicTitleEl.textContent = 'Ошибка загрузки темы';
        if (topicRulesEl) topicRulesEl.textContent = 'Не удалось загрузить правила';
        if (listEl) listEl.innerHTML = '<p>Не удалось загрузить сообщения</p>';
    });

  try {
    log(LOG_LEVELS.INFO, 'Инициализация формы сообщения');
    initMessageForm('messageForm', topicId);
  } catch (error) {
    log(LOG_LEVELS.ERROR, 'Ошибка инициализации формы сообщения', {
      error: error.message,
      stack: error.stack
    });
  }

  try {
    log(LOG_LEVELS.INFO, 'Загрузка сообщений');
    loadMessages(topicId);
  } catch (error) {
    log(LOG_LEVELS.ERROR, 'Ошибка загрузки сообщений', {
      error: error.message,
      stack: error.stack
    });
  }

  try {
    log(LOG_LEVELS.INFO, 'Инициализация менеджера ответов');
    initReplyManager();
  } catch (error) {
    log(LOG_LEVELS.ERROR, 'Ошибка инициализации менеджера ответов', {
      error: error.message,
      stack: error.stack
    });
  }

  log(LOG_LEVELS.INFO, 'Инициализация страницы темы завершена');
});

document.addEventListener('reloadMessages', () => {
  if (currentTopicId) {
    loadMessages(currentTopicId);
  }
});

// Добавляем глобальный обработчик ошибок для логирования
window.addEventListener('error', (event) => {
  log(LOG_LEVELS.ERROR, 'Глобальная ошибка', {
    message: event.message,
    filename: event.filename,
    lineno: event.lineno,
    colno: event.colno,
    error: event.error
  });
});

// Логирование unhandled rejections
window.addEventListener('unhandledrejection', (event) => {
  log(LOG_LEVELS.ERROR, 'Необработанное отклонение промиса', {
    reason: event.reason,
    promise: event.promise
  });
});