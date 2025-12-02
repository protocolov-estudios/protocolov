document.addEventListener('DOMContentLoaded', function() {
    const captchaContainer = document.querySelector('.captcha-container');
    const captchaImage = document.getElementById('captcha-image');
    const captchaInput = document.getElementById('captcha-input');
    const submitButton = document.getElementById('submit-captcha');
    const captchaMessage = document.getElementById('captcha-message');

    window.addEventListener('message', function(event) {
        if (event.data.type === 'showCaptcha') {
            captchaImage.src = event.data.captchaImage;
            captchaContainer.style.display = 'flex';
            captchaInput.value = '';
            captchaMessage.textContent = '';
        } else if (event.data.type === 'hideCaptcha') {
            captchaContainer.style.display = 'none';
        } else if (event.data.type === 'captchaResult') {
            if (event.data.success) {
                captchaMessage.textContent = 'CAPTCHA resuelto correctamente!';
                captchaMessage.className = 'message success';
                setTimeout(() => {
                    captchaContainer.style.display = 'none';
                }, 1000);
            } else {
                captchaMessage.textContent = 'CAPTCHA incorrecto. Inténtalo de nuevo.';
                captchaMessage.className = 'message error';
                captchaImage.src = event.data.newCaptchaImage; // Cargar nueva imagen
                captchaInput.value = '';
            }
        }
    });

    submitButton.addEventListener('click', function() {
        const inputText = captchaInput.value;
        fetch('https://' + GetParentResourceName() + '/submitCaptcha', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                solution: inputText
            })
        }).then(resp => resp.json()).then(resp => console.log(resp));
    });
});
