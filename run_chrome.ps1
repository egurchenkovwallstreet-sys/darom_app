# Запуск «Даром» в Chrome (если flutter не в PATH)
# Порт 8080 фиксированный — иначе вход не запоминается между запусками!
$flutter = "C:\src\flutter\bin\flutter.bat"
Set-Location $PSScriptRoot
& $flutter pub get
& $flutter run -d chrome --web-port=8080
