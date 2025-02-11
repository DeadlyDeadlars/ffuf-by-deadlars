#!/bin/bash

# Функция для анимации вращающегося слэша
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Логотип FFUF SCANNER
logo() {
    echo "  ______ _____  __  __ _____ "
    echo " |  ____|  __ \|  \/  |  __ \\"
    echo " | |__  | |__) | \  / | |__) |"
    echo " |  __| |  _  /| |\/| |  ___/ "
    echo " | |____| | \ \| |  | | |     "
    echo " |______|_|  \_\_|  |_|_|     "
    echo "By deadlars"
    echo
}

# Проверка наличия утилиты ffuf
check_ffuf() {
    if ! command -v ffuf &> /dev/null; then
        echo "Утилита ffuf не установлена. Установите её с помощью 'go install github.com/ffuf/ffuf@latest'."
        exit 1
    fi
}

# Основной скрипт
clear
logo
check_ffuf

# Запрос адреса сайта
read -p "Введите адрес сайта (например, https://example.com): " site_url

# Запрос пути к словарю
read -p "Введите путь к словарю (например, /path/to/wordlist.txt): " wordlist_path

# Проверка существования словаря
if [ ! -f "$wordlist_path" ]; then
    echo "Словарь не найден. Убедитесь, что путь указан правильно."
    exit 1
fi

# Сканирование директорий и страниц
echo -n "⌛ Сканирование сайта $site_url... "
ffuf -w "$wordlist_path" -u "$site_url/FUZZ" -o /tmp/ffuf_output.json -of json &> /dev/null &
spinner $!

# Обработка результатов
if [ $? -eq 0 ]; then
    echo -e "\n✅ Сканирование завершено!"
    results=$(jq -r '.results[] | "\(.status) \(.url)"' /tmp/ffuf_output.json)
    rm -f /tmp/ffuf_output.json

    if [ -z "$results" ]; then
        echo "❌ Ничего не найдено."
    else
        echo -e "\n=== Найденные директории и страницы ==="
        echo "$results" | while read -r line; do
            status=$(echo "$line" | awk '{print $1}')
            url=$(echo "$line" | awk '{print $2}')
            printf "🔗 %-10s %s\n" "[$status]" "$url"
        done
    fi
else
    echo -e "\n❌ Ошибка при сканировании."
fi
