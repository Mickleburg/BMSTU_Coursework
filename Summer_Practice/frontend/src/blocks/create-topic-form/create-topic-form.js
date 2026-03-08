import { createTopic } from '../../scripts/api.js';
import { loadTopics } from '../topics/__list/topics__list.js';

export function initTopicForm(formId) {
    const form = document.getElementById(formId);
    if (!form) return;

    const submitButton = form.querySelector('button[type="submit"]');
    
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        console.log('Форма отправлена!');
        
        if (!submitButton) return;

        const title = form.elements.title.value.trim();
        console.log('Название темы:', title);
        
        if (!title) {
            alert('Название темы обязательно!');
            return;
        }
        
        // Сохраняем исходное состояние кнопки
        const originalText = submitButton.textContent;
        const originalClasses = submitButton.className;
        
        // Устанавливаем состояние "загрузка"
        submitButton.textContent = 'Создание...';
        submitButton.className = originalClasses + ' button_loading';
        submitButton.disabled = true;

        const formData = new FormData(form);
        const topicData = {
            title: formData.get('title'),
            rules: formData.get('rules'),
        };
        
        console.log('Данные для отправки:', topicData);

        try {
            console.log('Отправляем запрос на создание темы...');
            const result = await createTopic(topicData);
            console.log('Тема создана успешно:', result);
            
            form.reset();
            document.getElementById('createTopicModal').classList.add('modal_hidden');
            
            console.log('Обновляем список тем...');
            await loadTopics(); // Обновляем список тем
            alert('Тема успешно создана!');
        } catch(error) {
            console.error('Ошибка создания темы:', error);
            alert('Не удалось создать тему: ' + error.message);
        } finally {
            // Восстанавливаем исходное состояние кнопки
            if (submitButton) {
                submitButton.textContent = originalText;
                submitButton.className = originalClasses;
                submitButton.disabled = false;
            }
        }
    });
}