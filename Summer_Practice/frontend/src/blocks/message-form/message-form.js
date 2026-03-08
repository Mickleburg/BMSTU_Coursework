import { createMessage } from '../../scripts/api.js';

export function initMessageForm(formId, topicId) {
  const form = document.getElementById(formId);
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const content = form.querySelector('textarea').value.trim(); // ← исправлено
    if (!content) return;

    try {
      const message = await createMessage(topicId, { 
        content: content,  // ← исправлено (было text)
        parentId: null 
      });
      console.log('Сообщение создано:', message);
      form.reset();
      const event = new CustomEvent('reloadMessages');
      document.dispatchEvent(event);

      location.reload();
    } catch (err) {
      console.error('Ошибка отправки сообщения:', err);
      alert('Не удалось отправить сообщение');
    }
  });
}