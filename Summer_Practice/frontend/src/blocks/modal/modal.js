export function initModal(modalId, openButtonId, closeButtonClass) {
    const modal = document.getElementById(modalId);
    const openButton = document.getElementById(openButtonId);

    if (!modal || !openButton) {
        console.error('Элементы модального окна не найдены');
        return;
    }

    console.log('Модальное окно инициализировано:', modalId);

    const closeButtons = modal.querySelectorAll(`.${closeButtonClass}`);
    
    openButton.addEventListener('click', () => {
        console.log('Открываем модальное окно');
        modal.classList.remove('modal_hidden');
        modal.classList.add('modal_active');
    });

    closeButtons.forEach(button => {
        button.addEventListener('click', () => {
            console.log('Закрываем модальное окно');
            modal.classList.add('modal_hidden');
            modal.classList.remove('modal_active');
        });
    });

    // Клик вне модального окна
    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            console.log('Закрываем модальное окно по клику вне');
            modal.classList.add('modal_hidden');
            modal.classList.remove('modal_active');
        }
    });

    // Закрытие по ESC
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && !modal.classList.contains('modal_hidden')) {
            console.log('Закрываем модальное окно по ESC');
            modal.classList.add('modal_hidden');
            modal.classList.remove('modal_active');
        }
    });
}