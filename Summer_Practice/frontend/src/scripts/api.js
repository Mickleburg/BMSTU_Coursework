const API_BASE = '/api';

// Проверка ответа сервера
function checkResponse(response) {
    if (!response.ok) {
        return response.text().then(text => {
            let errorInfo = `Ошибка ${response.status}: ${response.statusText}`;
            try {
                const errorData = JSON.parse(text);
                errorInfo += ` - ${errorData.message || text}`;
            } catch {
                errorInfo += ` - ${text}`;
            }
            throw new Error(errorInfo);
        });
    }
    return response.json();
}

export async function getTopics() {
    const response = await fetch(`${API_BASE}/topics`);
    return checkResponse(response);
}

export async function createTopic(topicData) {
    const response = await fetch(`${API_BASE}/topics`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(topicData)
    });
    return checkResponse(response);
}

export async function getTopic(topicId) {
    const response = await fetch(`${API_BASE}/topics/${topicId}`);
    return checkResponse(response);
}

export async function getMessages(topicId) {
    const response = await fetch(`${API_BASE}/topics/${topicId}/messages`);
    return checkResponse(response);
}

export async function createMessage(topicId, messageData) {
    const payload = {
        topic_id: parseInt(topicId),
        content: messageData.content,  // ← ИСПРАВЛЕНО: было text, стало content
        parent_id: messageData.parentId ?? null
    };
    
    console.log('Отправка сообщения:', payload);  // ← для отладки
    
    const response = await fetch(`${API_BASE}/messages`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    });
    return checkResponse(response);
}