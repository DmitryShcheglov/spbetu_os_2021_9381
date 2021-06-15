# Операционные системы (группа 9381)

## Таблица текущего состояния сдачи работ

| ##   | ФИО          | Github              | lab1  | lab2  | lab3  | lab4  | lab5  | lab6  | lab7  |
| ---- | ------------ | ------------------- | ----- | ----- | ----- | ----- | ----- | ----- | ----- |
| 1    | Аухадиев     | Auhadiev            | 22.03 | 26.05 | 26.05 | 29.05 | 29.05 | 29.05 | 26.05 |
| 2    | Андрух       | Irina8888           | 13.05 | 13.05 | 13.05 | 13.05 | 13.05 | 13.05 | 13.05 |
| 3    | Гурин        |                     |       |       |       |       |       |       |       |
| 4    | Давыдов      | Dmitrydavka         | 13.05 | 14.05 | 13.05 | 29.05 | 29.05 |       |       |
| 5    | Игнашов      | ImSOLty             | 26.05 | 26.05 | 26.05 | 26.05 | 26.05 | 26.05 | 26.05 |
| 6    | Камакин      | dkamakin            | 28.02 | 28.02 | 28.04 | 28.04 | 28.04 | 28.04 | 12.05 |
| 7    | Колованов    | TheLifes08          | 11.02 | 12.05 | 12.05 | 12.05 | 12.05 | 12.05 | 12.05 |
| 8    | Любимов      | VladimirLyubimov    | 15.06 | 15.06 |       |       |       |       |       |
| 9    | Матвеев      | Andrexus23          | 22.02 | 28.02 | 31.03 | 31.03 | 12.05 | 12.05 | 14.05 |
| 10   | Москаленко   | moskalenko9381      | 28.02 | 28.02 | 28.04 | 28.04 | 28.04 | 28.04 | 12.05 |
| 11   | Николаев     | EFFECT322           | 26.05 | 26.05 | 26.05 | 26.05 | 26.05 | 26.05 | 26.05 |
| 12   | Прашутинский | kirja1980           | 29.05 | 29.05 | 29.05 | 29.05 | 29.05 | 29.05 | 29.05 |
| 13   | Прибылов     | PribylovNikita      | 29.05 | 29.05 | 29.05 |       |       |       |       |
| 14   | Птичкин      | PtichkinSergey      | 13.05 | 13.05 | 13.05 | 13.05 | 13.05 | 13.05 | 26.05 |
| 15   | Семенов      | Sashauxgit          | 28.02 | 15.06 | 29.05 | 29.05 | 15.06 | 15.06 | 15.06 |
| 16   | Судаков      | YudjinSud           | 29.05 | 29.05 | 29.05 | 15.06 | 15.06 | 29.05 | 15.06 |
| 17   | Фоминенко    |                     |       |       |       |       |       |       |       |
| 18   | Шахин        | shakhinn            | 22.02 | 28.02 | 31.03 | 31.03 | 12.05 | 29.04 | 12.05 |

## Дедлайны

| Лабораторные работы | Срок  | | Ответы на вопросы moodle | Срок  |
| ------------------- | ----- |-| ------------------------ | ----- |
|       1 - 2         | 01.03 | |          1 - 2           | 20.03 |
|       3 - 4         | 01.04 | |          3 - 5           | 15.04 |
|       5 - 6         | 01.05 | |          6 - 7           | 01.05 |
|         7           | 15.05 | |          8 - 9           | 15.05 |
|                     |       | |         10 - 11          | 01.06 |

## Распространенные проблемы

[Перечеслены вот тут](./FAQ.md)

[Методические указания](./os_labs_guide.pdf)

## Правила работы с репозиторием (прочитайте внимательно!)

 - Для начала работы каждый студент делает форк (fork) репозитория на свой GitHub аккаунт.
Каждый студент работает строго в своей директории firstname/ , где firstname - название директории в соотвтествии с вашей фамилией в таблицей, начинающаяся со **маленькой** буквы. Работа в чужих директориях **строго-настрого запрещается**.

> Как сделать так, чтобы этого не произошло? Не надо синхронизировать свой репозиторий с master-веткой origin-репозитория. Не надо делать fetch-и с origin-репозитория или тем более fork-ов ваших коллег. Сделали один раз fork -- с ним и работаете, в своей директории. Не надо удалять никаких файлов: ни чужих, ни своих с других веток, например. Не надо выполнять merge своих веток лишний раз, ибо это просто излишне. Работаете вы в отдельных ветках для каждой из лабораторных. Все это -- настоятельные советы, которые должны нивелировать возможность конфликтов при работе. Большая просьба их соблюдать, уважая время и труд ваших коллег.

- Для каждой лабораторной требуется создавать отдельную директорию lab#, где # - номер - лабораторной от 1 до 7. Пример устройства корневой директории курса:

```
.
├── efremov
│   ├── lab1
│   │   ├── report.pdf
│   │   ├── report.odt
│   │   └── source.asm
│   └── lab2
│   │   ├── report.pdf
│   │   ├── report.odt
│   │   └── source.asm
├── ivanova
│   ├── lab1
│   │   ├── report.pdf
│   │   ├── report.odt
│   │   └── source.asm
│   └── lab2
│   │   ├── report.pdf
│   │   ├── report.odt
│   │   └── source.asm
└── README.md
```

- Внутри должны находиться:
    - Исходный код лабораторных программ;
    - Отчет в формате pdf по шаблону с [сайта университета](https://etu.ru/ru/studentam/dokumenty-dlya-ucheby/). Отчеты, оформленные иначе приниматься не будут. Не тратьте наше общее время.

> На всякий случай, каковы требования к оформлению: 14й шрифт Times New Roman (или похожий, например, свободный шрифты Linux Libertine или Liberation Serif), 1.5 строки интервал, красная строка; заголовки должны иметься для каждого из разделов докумета, имеют такой же 14pt шрифт, выделяются жирным; обязательные разделы: цель работы, ход выполнения, ответы на вопросы (пожалуйста, пишите сами формулировки вопросов перед ответами!), выводы; копирование текста методички в отчет вовсе не требуется; все изображения и листинги должны быть информативные (пример неинформативного скриншота: скриншот всего рабочего стола с открытым FAR-ом посреди какого-то представления исполняемого модуля. Как сделать информативнее: уменьшить размер изображения до тех размеров, в которые помещается ровно тот участок представления, который что-то отображает (например, границу PSP), подчеркнуть, выделить требуемый участок изображения) пронумерованы и подписаны тем же 14pt обычным шрифтом, выровненным по центру (Пример: Рисунок 2 -- Представление сегмента стека в памяти.), на рисунок, раз уж вы его представили, вы где-то должны ссылаться (иначе зачем он нужен вообще?). Страницы нумеруются в нижней части документа, по центру (если используете шаблон с сайта вуза, все уже сделано за вас). Пожалуйста, соблюдайте эти не сложные требования к оформлению: их так гораздо проще как писать (имеется четкая структура, все эти требования по-умолчанию уже есть в вузовском шаблоне), так и проверять.

- Для каждой лабораторной создается отдельная новая ветка (branch) из master-ветви с названием вида < firstname_lab# >, где firstname - фамилия (аналогично названию вашей личной директории), а # - номер работы, тоже со строчной буквы). Пример создания ветви и перехода на нее:
```
git checkout master
git checkout -b efremov_lab1
```
- Для сдачи лабораторной работы создается пул-реквест (pull-request) из вашей ветки с лабораторной работой в master-ветку общего репозитория курса. В начале заголовка пул-реквеста пишется "[READY] ", после - Фамилия латиницей, после - lab#. (Пример: [READY] Efremov lab1). Формат важен, так как для разбора ваших pull request используется поиск по ключевым словам.
- Для сдачи работы требуется закрытый pull request со слиянием (merge) вашей ветки в общий репозиторий. В таком случае работа считается проверенной.
- Если имеются какие-либо нарекания к предложенным студентом файлам, то все замечания пишутся проверяющим в комментарии пул-реквеста, а так же изменяется префикс заголовка на [WIP].
- Напоминание: коммиты в ветку, которую студент отправляет на пул-реквест отображаются в самом пул-реквесте. Делать новый пул-реквест не надо.
- Закончив исправления, студент пишет об этом отдельным комментарием, указывая, возможно, пояснения к исправлениям, а так же меняет префикс заголовка пул-реквеста снова на [READY], тем самым показывая, что его работа готова к повторному просмотру.
- Курс лабораторных считается завершенным полностью, если в основном репозитории находятся директории всех 7 лабораторных работ студента.
