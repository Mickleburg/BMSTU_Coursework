import { initModal } from '../blocks/modal/modal.js';
import { initTopicForm } from '../blocks/create-topic-form/create-topic-form.js';
import { loadTopics } from '../blocks/topics/__list/topics__list.js';

document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM загружен, инициализируем приложение...');
    
    // Инициализация модального окна
    console.log('Инициализируем модальное окно...');
    initModal('createTopicModal', 'createTopicBtn', 'modal__close-btn');
    
    // Инициализация формы создания темы
    console.log('Инициализируем форму создания темы...');
    const form = document.getElementById('topicForm');
    if (form) {
        console.log('Форма найдена, инициализируем...');
        initTopicForm('topicForm');
    } else {
        console.error('Форма создания темы не найдена');
    }
    
    // Загрузка списка тем
    console.log('Загружаем список тем...');
    loadTopics();
    
    console.log('Приложение инициализировано!');
});