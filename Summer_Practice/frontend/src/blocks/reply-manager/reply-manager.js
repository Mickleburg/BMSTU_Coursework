export function initReplyManager() {
    // Собираем все необходимые элементы
    const elements = {
        messagesContainer: document.getElementById('messagesList'),
        replyInfo: document.getElementById('replyInfo'),
        replyText: document.getElementById('replyText'),
        parentIdInput: document.getElementById('parentId'),
        cancelButton: document.getElementById('cancelReplyBtn')
    };

    // Проверка необходимых элементов с детализацией
    const missingElements = Object.entries(elements)
        .filter(([key, element]) => {
            // Для cancelButton проверяем только если он нужен для основной функциональности
            if (key === 'cancelButton') return false;
            return !element;
        })
        .map(([key]) => key);

    if (missingElements.length > 0) {
        console.error('Не найдены необходимые элементы для работы с ответами:', missingElements.join(', '));
        return;
    }

    // Обработчик клика по кнопкам "Ответить"
    elements.messagesContainer.addEventListener('click', (e) => {
        if (e.target.classList.contains('message__reply-btn')) {
            const messageId = e.target.dataset.id;
            const messageText = e.target.dataset.text;
            
            // Установка данных в форму
            elements.parentIdInput.value = messageId;
            elements.replyText.textContent = messageText;
            elements.replyInfo.style.display = 'block';
            
            // Прокрутка к форме
            document.querySelector('.new-message').scrollIntoView({
                behavior: 'smooth'
            });
        }
    });

    // Обработчик кнопки отмены ответа (если она есть)
    if (elements.cancelButton) {
        elements.cancelButton.addEventListener('click', () => {
            elements.parentIdInput.value = '';
            elements.replyInfo.style.display = 'none';
        });
    }
}