#!/bin/bash

# Проверка, существует ли файл 07_password
if [ ! -e /etc/grub.d/07_password ]; then
  echo "Файл 07_password не существует. Смена пароля GRUB отменена."
  exit 1
fi

# Проверка, можно ли записать в файл 07_password
# -w - это условие, которое проверяет наличие прав на запись к файлу. Если файл доступен для записи, то это условие вернет истину (true)
# ! - это логический оператор "не". Он инвертирует результат проверки, так что ! -w означает "не имеет прав на запись".
if [ ! -w /etc/grub.d/07_password ]; then
  echo "У вас нет разрешения на запись в файл 07_password."
  exit 2
fi

# Запрашиваем имя логина
read -s -p "Введите имя администратора системы: " user
echo

# Запрашиваем пароль у пользователя
read -s -p "Введите новый пароль для GRUB: " password
echo

# Повторно запрашиваем пароль для подтверждения
read -s -p "Повторите пароль: " password_confirm
echo

# Проверка на совпадение паролей
if [ "$password" != "$password_confirm" ]; then
  echo "Пароли не совпадают. Смена пароля отменена."
  exit 3
fi

# Генерация хэша пароля с помощью grub-mkpasswd-pbkdf2
# echo -e, вы можете выводить такие escape-последовательности, как \n для перевода строки, \t для табуляции и другие.
# | awk '{print $5}' - Берем только пятый столбец, разделитель пробел.
hashed_password=$(echo -e "$password\n$password_confirm" | grub-mkpasswd-pbkdf2 | awk '{print $5}' | tr -d '\n')

# Создание содержимого файла /etc/grub.d/07_password
cat <<EOL > /etc/grub.d/07_password
#!/bin/sh
cat <<EOF
set superusers="$user"
password_pbkdf2 $user $hashed_password
EOF
EOL

# Установка прав на файл 07_password
chmod 755 /etc/grub.d/07_password

# Обновление настроек GRUB
# & - это символ, который используется для объединения stdout и stderr.
# Итак, выражение &>/dev/null используется для перенаправления как стандартного вывода (stdout),
# так и стандартного вывода ошибок (stderr) в /dev/null, что означает, что никакой вывод или сообщения об ошибках не будут видны в терминале. 
update-grub &>/dev/null
# "$?" означает значение кода возврата предыдущей команды.
if [ "$?" -eq "0" ]; then
  echo "Новый пароль GRUB установлен успешно"
else
  echo "Ошибка: не удалось обновить конфигурационный файл GRUB"
  exit 4
fi
exit 0
