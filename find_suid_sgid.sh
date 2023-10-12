#!/bin/bash

# Проверка, что скрипт запущен от имени root
if [ "$EUID" -ne 0 ]; then
  echo "Скрипт должен быть запущен от имени root. Выход."
  exit 1
fi

# Запрос имени файла для сохранения информации если не введено в качестве аргумента.
# [ -z "$1" ] проверяет, является ли значение переменной $1 пустым
if [ -z "$1" ]; then
  read -p "Введите имя файла для сохранения информации: " output_file
else
  output_file="$1"
fi

# Проверка, что файл для сохранения информации существует
# -e - это опция, которая проверяет существование файла или директории
if [ -e "$output_file" ]; then
  echo "Файл '$output_file' уже существует. Перезаписать? (y/n)"
  read confirm
  if [ "$confirm" != "y" ]; then
    echo "Операция отменена."
    exit 2
  fi
fi

# Получаем текущую дату и время в указанном формате
current_datetime=$(date +"%Y-%m-%d %H:%M:%S")

# Ищем файлы с установленными битами SUID и SGID
# / - это начальная директория
# -type f - это опция find, которая ограничивает результаты поиска только файлами
# \( ... \) - это синтаксис для группировки условий в командах вроде find, grep
# -perm -u=s - это условие, которое проверяет, что у файла установлен бит SUID.
# -o - это логический оператор "или", который соединяет два условия.
# -perm -g=s - это условие, которое проверяет, что у файла установлен бит SGID
suid_files=$(find / -type f \( -perm -u=s -o -perm -g=s \) 2>/dev/null)

# Создаем файл для сохранения информации
echo "$current_datetime" > "$output_file"

# Обходим найденные файлы и записываем информацию в файл
for file in $suid_files; do
  file_basename=$(basename "$file")
  checksum=$(sha1sum "$file" | awk '{print $1}')
  permissions=""
  if test -u "$file"; then
    permissions+="u"
  fi
  if test -g "$file"; then
    permissions+="g"
  fi
  printf "%-30s %-40s %s\n" "$file_basename" "$checksum" "$permissions" >> "$output_file"
done

echo "Информация сохранена в файл: $output_file"
