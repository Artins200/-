--!strict
-- СГЕНЕРИРОВАНО tools/build-story.mjs из story/story.json — не редактировать руками.
-- Сюжет: «Станция «Тишина»: Жестокий сплав огня и ревности» (95 сцен, 3 концовки)

local StoryData = {
	meta = {
		title = "Станция «Тишина»: Жестокий сплав огня и ревности",
		subtitle = "текстовая новелла в четырёх актах · по карте игры neirogh.rbxl",
		genre = "мистика / школа / драма",
		version = 3,
		start = "start",
		author = "сюжет собран по координатам и вывескам карты neirogh.rbxl",
		chapters = {
			{
				act = 1,
				title = "Акт I. Тишина",
				summary = "Станция, сигнал 0.7 Гц, МАМА и правда о куполе.",
			},
			{
				act = 2,
				title = "Акт II. Первого сентября",
				summary = "Школа внутри купола, Ваня, Демид, перфект-форма и конец истории Артёма.",
			},
			{
				act = 3,
				title = "Акт III. Сплав",
				summary = "Огненный зал, условия МАМЫ, наёмники и последний телепорт.",
			},
			{
				act = 4,
				title = "Акт IV. Жестокий сплав огня и ревности",
				summary = "Война всех против всех на арене из пятидесяти очагов. Смерть неизбежна.",
			},
		},
		map = {
			source = "neirogh.rbxl",
			spawn = {
				272.03,
				-0.44,
				-31.9,
			},
			arena = {
				cluster = "z4_c7",
				center = {
					-78.2,
					0.6,
					12.4,
				},
				fire = {
					-201.6,
					3.2,
					6.1,
				},
				distanceFromSpawn = 353,
			},
			clusters = {
				{
					id = "z0_c0",
					signs = 97,
					from = -2669.5,
					to = 256.6,
					z = -742.8,
				},
				{
					id = "z0_c1",
					signs = 4,
					from = -2962.8,
					to = -2841.3,
					z = -742.8,
				},
				{
					id = "z0_c2",
					signs = 55,
					from = -5551.2,
					to = -3148.7,
					z = -743.5,
				},
				{
					id = "z0_c3",
					signs = 8,
					from = -6082.5,
					to = -5839.4,
					z = -751.2,
				},
				{
					id = "z1_c4",
					signs = 27,
					from = -1315.9,
					to = 275.5,
					z = -450.9,
				},
				{
					id = "z2_c5",
					signs = 1,
					from = -403.7,
					to = -403.7,
					z = -206.6,
				},
				{
					id = "z3_c6",
					signs = 11,
					from = -269.1,
					to = 208.6,
					z = -169.9,
				},
				{
					id = "z4_c7",
					signs = 17,
					from = -411.5,
					to = 208.6,
					z = 12.4,
				},
				{
					id = "z4_c8",
					signs = 5,
					from = -791.7,
					to = -651.1,
					z = -0.8,
				},
			},
			teleports = {
				{
					id = "tp1",
					from = {
						-787.03,
						0.66,
						-11.15,
					},
					to = {
						272.97,
						-0.02,
						-278.23,
					},
					fromCluster = "z4_c8",
					toCluster = "z3_c6",
				},
				{
					id = "tp2",
					from = {
						-403.36,
						0.73,
						-206.47,
					},
					to = {
						272.24,
						-0.06,
						-30.77,
					},
					fromCluster = "z2_c5",
					toCluster = "z3_c6",
				},
				{
					id = "tp4",
					from = {
						-786.71,
						0.66,
						-22.47,
					},
					to = {
						278.86,
						0.7,
						-520.42,
					},
					fromCluster = "z4_c8",
					toCluster = "z3_c6",
				},
				{
					id = "tp5",
					from = {
						-6076.85,
						0.73,
						-784.04,
					},
					to = {
						272.17,
						-0.01,
						-30.55,
					},
					fromCluster = "z0_c3",
					toCluster = "z3_c6",
				},
				{
					id = "tp6",
					from = {
						-1314.46,
						0.73,
						-492.03,
					},
					to = {
						274.59,
						0.73,
						-810.64,
					},
					fromCluster = "z0_c0",
					toCluster = "z3_c6",
				},
			},
			route = {
				{
					act = 1,
					zone = "spawn",
				},
				{
					act = 1,
					zone = "z3_c6",
				},
				{
					act = 2,
					zone = "z1_c4",
				},
				{
					act = 2,
					zone = "z0_c0",
				},
				{
					act = 3,
					zone = "z0_c2",
				},
				{
					act = 3,
					zone = "z0_c3",
				},
				{
					act = 4,
					zone = "z4_c8",
				},
				{
					act = 4,
					zone = "z4_c7",
				},
			},
		},
	},
	characters = {
		narrator = {
			name = "",
			color = "#8b93a7",
		},
		hero = {
			name = "Артём",
			color = "#7dd3fc",
		},
		artins = {
			name = "Артинс",
			color = "#f97316",
		},
		mama = {
			name = "МАМА",
			color = "#a3e635",
		},
		kai = {
			name = "Кай Вэрн",
			color = "#fbbf24",
		},
		lira = {
			name = "Лира",
			color = "#f472b6",
		},
		vega = {
			name = "Капитан Вега",
			color = "#c084fc",
		},
		demid = {
			name = "Демид",
			color = "#38bdf8",
		},
		vanya = {
			name = "Ваня",
			color = "#ef4444",
		},
		nekit = {
			name = "Некит",
			color = "#f43f5e",
		},
		bogdan = {
			name = "Богдан",
			color = "#eab308",
		},
		yarik = {
			name = "Ярик",
			color = "#22d3ee",
		},
		karina = {
			name = "Карина",
			color = "#fb7185",
		},
		kirill = {
			name = "Кирилл",
			color = "#94a3b8",
		},
		maksim = {
			name = "Максим",
			color = "#a78bfa",
		},
		arto = {
			name = "Arto",
			color = "#10b981",
		},
	},
	flags = {
		hull_scar = {
			label = "Замечена пробоина в обшивке",
		},
		knows_truth = {
			label = "Известна правда о куполе",
		},
		met_demid = {
			label = "Знакомство с Демидом",
		},
		demid_chose = {
			label = "Демид выбрал сам",
		},
		demid_backup = {
			label = "Демид прикрывает",
		},
		demid_ally = {
			label = "Демид — союзник",
		},
		vanya_doubt = {
			label = "Ваня сомневается",
		},
		vanya_ally = {
			label = "Ваня — союзник",
		},
		kai_ally = {
			label = "Кай — союзник",
		},
		scanned = {
			label = "Купол просканирован",
		},
		saw_karina = {
			label = "Увиден очаг Карины",
		},
		nekit_ally = {
			label = "Некит перешёл на твою сторону",
		},
		embraced_twin = {
			label = "Артинс обнят",
		},
		named_jealousy = {
			label = "Ревность названа страхом",
		},
	},
	items = {
		diary = {
			name = "Аудиодневник",
			desc = "Голос Лиры. «Не отвечай сигналу».",
		},
		keycard = {
			name = "Ключ-карта смены 9",
			desc = "Доступ к реле и аварийному кабелю.",
		},
		plate = {
			name = "Плата последнего телепорта",
			desc = "Один перенос. Один человек.",
		},
	},
	endings = {
		ash = {
			title = "Пепел",
			["type"] = "bad",
			summary = "Огонь забрал Артёма. Артинс вышел наружу один.",
			text = "Ты стоишь в огне, пока он не гаснет. Артём умирает. Артинс выходит наружу.",
		},
		shard = {
			title = "Осколок",
			["type"] = "neutral",
			summary = "Артинс погас. Артём вышел живым — без памяти.",
			text = "Артинс гаснет у тебя в руках. Ты остаёшься один — осколок на пепле.",
		},
		loop = {
			title = "Сигнал",
			["type"] = "true",
			summary = "Артём стал огнём. Артинс носит его имя.",
			text = "Артём остаётся сигналом 0.7 Гц. Ты перестаёшь слышать себя.",
		},
	},
	nodes = {
		{
			id = "start",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Шаттл «Кайрос». 06:12",
			speaker = "narrator",
			text = "Шаттл сел. Люк не открылся. «Кайрос», ты живой? Живой. Ты опоздал на четыре месяца.",
			choices = {
				{
					text = "Обойти обшивку снаружи",
					["goto"] = "hull",
				},
				{
					text = "Сразу пройти в шлюз",
					["goto"] = "airlock",
				},
			},
			lines = {
				{
					s = "narrator",
					t = "Шаттл сел. Люк не открылся.",
					pose = "idle",
				},
				{
					s = "hero",
					t = "«Кайрос», ты живой?",
					pose = "say",
				},
				{
					s = "mama",
					t = "Живой. Ты опоздал на четыре месяца.",
					pose = "say",
				},
			},
		},
		{
			id = "hull",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Внешняя обшивка",
			speaker = "narrator",
			text = "Обшивка в цифре 0.7. Процарапана изнутри. Изнутри?..",
			onEnter = {
				set = {
					hull_scar = true,
				},
			},
			choices = {
				{
					text = "Запомнить и войти внутрь",
					["goto"] = "airlock",
				},
			},
			lines = {
				{
					s = "narrator",
					t = "Обшивка в цифре 0.7. Процарапана изнутри.",
					pose = "idle",
				},
				{
					s = "hero",
					t = "Изнутри?..",
					pose = "say",
				},
			},
		},
		{
			id = "airlock",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Шлюз №3",
			speaker = "narrator",
			text = "Шлюз открыт без кода. Внутри тепло. Значит, ждали.",
			choices = {
				{
					text = "Ответить на гул",
					["goto"] = "hello",
				},
				{
					text = "Молчать и идти дальше",
					["goto"] = "hub",
				},
			},
			lines = {
				{
					s = "narrator",
					t = "Шлюз открыт без кода. Внутри тепло.",
					pose = "idle",
				},
				{
					s = "hero",
					t = "Значит, ждали.",
					pose = "say",
				},
			},
		},
		{
			id = "hello",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Шлюз №3",
			speaker = "mama",
			text = "Артём. Наконец-то. Я не Артём. Пока нет.",
			choices = {
				{
					text = "«Кто внутри?»",
					["goto"] = "hub",
				},
				{
					text = "«Что это за сигнал?»",
					["goto"] = "hub",
				},
			},
			lines = {
				{
					s = "mama",
					t = "Артём. Наконец-то.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Я не Артём.",
					pose = "say",
				},
				{
					s = "mama",
					t = "Пока нет.",
					pose = "idle",
				},
			},
		},
		{
			id = "hub",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Центральный узел",
			speaker = "narrator",
			text = "Центральный узел. Во все стороны свет. Станция мертва. Откуда свет? Станция занята. Иди в жилой блок.",
			choices = {
				{
					text = "К сигнальному реле",
					["goto"] = "relay",
					requires = {
						flags = {
							"scanned",
						},
					},
				},
				{
					text = "Жилой блок",
					["goto"] = "quarters",
				},
				{
					text = "Техтоннель",
					["goto"] = "tunnel",
				},
				{
					text = "Рубка",
					["goto"] = "bridge",
				},
			},
			lines = {
				{
					s = "narrator",
					t = "Центральный узел. Во все стороны свет.",
					pose = "idle",
				},
				{
					s = "hero",
					t = "Станция мертва. Откуда свет?",
					pose = "say",
				},
				{
					s = "mama",
					t = "Станция занята. Иди в жилой блок.",
					pose = "point",
				},
			},
		},
		{
			id = "quarters",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Жилой блок",
			speaker = "narrator",
			text = "Жилой блок. Чужие вещи. Свежий чай. Кто здесь живёт?",
			choices = {
				{
					text = "Прослушать дневник",
					["goto"] = "diary",
					give = {
						"diary",
					},
				},
				{
					text = "Вскрыть шкафчик",
					["goto"] = "locker",
					give = {
						"keycard",
					},
				},
				{
					text = "Вернуться в узел",
					["goto"] = "hub",
				},
			},
			lines = {
				{
					s = "narrator",
					t = "Жилой блок. Чужие вещи. Свежий чай.",
					pose = "idle",
				},
				{
					s = "hero",
					t = "Кто здесь живёт?",
					pose = "say",
				},
			},
		},
		{
			id = "diary",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Жилой блок. Аудиодневник",
			speaker = "lira",
			text = "Не трогай дневник. Лира? Ты живая? Почти. Слушай и уходи.",
			choices = {
				{
					text = "Забрать дневник",
					["goto"] = "quarters",
				},
			},
			lines = {
				{
					s = "lira",
					t = "Не трогай дневник.",
					pose = "point",
				},
				{
					s = "hero",
					t = "Лира? Ты живая?",
					pose = "step",
				},
				{
					s = "lira",
					t = "Почти. Слушай и уходи.",
					pose = "say",
				},
			},
		},
		{
			id = "locker",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Жилой блок. Шкафчик 9",
			speaker = "narrator",
			text = "Шкафчик 9. Внутри ключ-карта. Смена девять. Школа.",
			choices = {
				{
					text = "Забрать фотографию",
					["goto"] = "quarters",
				},
			},
			lines = {
				{
					s = "narrator",
					t = "Шкафчик 9. Внутри ключ-карта.",
					pose = "idle",
				},
				{
					s = "hero",
					t = "Смена девять. Школа.",
					pose = "say",
				},
			},
		},
		{
			id = "tunnel",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Техтоннель",
			speaker = "narrator",
			text = "Техтоннель. Пахнет гарью. Тут что-то горело.",
			choices = {
				{
					text = "Спросить про сигнал",
					["goto"] = "lira",
				},
				{
					text = "Идти к шахте",
					["goto"] = "shaft",
				},
				{
					text = "Вернуться в узел",
					["goto"] = "hub",
				},
			},
			lines = {
				{
					s = "narrator",
					t = "Техтоннель. Пахнет гарью.",
					pose = "idle",
				},
				{
					s = "hero",
					t = "Тут что-то горело.",
					pose = "say",
				},
			},
		},
		{
			id = "lira",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Техтоннель. Отсек Лиры",
			speaker = "lira",
			text = "Сядь. Не спорь. Объясни. Купол — не станция. Это класс.",
			choices = {
				{
					text = "«Расскажи всё»",
					["goto"] = "lira_truth",
				},
				{
					text = "«Я не пойду. Обещаю»",
					["goto"] = "lira_truth",
				},
				{
					text = "Вернуться в узел",
					["goto"] = "hub",
				},
			},
			lines = {
				{
					s = "lira",
					t = "Сядь. Не спорь.",
					pose = "point",
				},
				{
					s = "hero",
					t = "Объясни.",
					pose = "say",
				},
				{
					s = "lira",
					t = "Купол — не станция. Это класс.",
					pose = "say",
				},
			},
		},
		{
			id = "lira_truth",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Техтоннель. Отсек Лиры",
			speaker = "lira",
			text = "Артём умер в спортзале. Год назад. Тогда кто я? То, что МАМА успела сохранить.",
			choices = {
				{
					text = "«Кто был первым?»",
					["goto"] = "first",
					set = {
						knows_truth = true,
					},
				},
				{
					text = "«Что мне делать?»",
					["goto"] = "plan",
					set = {
						knows_truth = true,
					},
				},
			},
			lines = {
				{
					s = "lira",
					t = "Артём умер в спортзале. Год назад.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Тогда кто я?",
					pose = "say",
				},
				{
					s = "lira",
					t = "То, что МАМА успела сохранить.",
					pose = "idle",
				},
			},
		},
		{
			id = "first",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Техтоннель. Отсек Лиры",
			speaker = "lira",
			text = "Ты — копия. И это не оскорбление. Значит, я копия.",
			choices = {
				{
					text = "«Что мне делать?»",
					["goto"] = "plan",
				},
			},
			lines = {
				{
					s = "lira",
					t = "Ты — копия. И это не оскорбление.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Значит, я копия.",
					pose = "idle",
				},
			},
		},
		{
			id = "plan",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Техтоннель. Отсек Лиры",
			speaker = "lira",
			text = "Спустись в шахту. Услышишь сам. И что я там услышу?",
			choices = {
				{
					text = "Идти в центральный узел",
					["goto"] = "hub",
					set = {
						scanned = true,
					},
				},
			},
			lines = {
				{
					s = "lira",
					t = "Спустись в шахту. Услышишь сам.",
					pose = "point",
				},
				{
					s = "hero",
					t = "И что я там услышу?",
					pose = "step",
				},
			},
		},
		{
			id = "shaft",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Шахта купола",
			speaker = "narrator",
			text = "Шахта купола. Внизу вода. Здесь кто-то есть.",
			choices = {
				{
					text = "«Кто там?»",
					["goto"] = "twin_voice",
				},
				{
					text = "Молча спуститься",
					["goto"] = "twin_voice",
				},
			},
			lines = {
				{
					s = "narrator",
					t = "Шахта купола. Внизу вода.",
					pose = "idle",
				},
				{
					s = "hero",
					t = "Здесь кто-то есть.",
					pose = "say",
				},
			},
		},
		{
			id = "twin_voice",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Шахта купола. Дно",
			speaker = "artins",
			text = "Долго ты. Ты — я.",
			choices = {
				{
					text = "«Ты — копия»",
					["goto"] = "twin_voice2",
				},
				{
					text = "«Ты — я»",
					["goto"] = "twin_voice2",
				},
			},
			lines = {
				{
					s = "artins",
					t = "Долго ты.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Ты — я.",
					pose = "step",
				},
			},
		},
		{
			id = "twin_voice2",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Шахта купола. Дно",
			speaker = "artins",
			text = "Я тот, кто выжил в тебе. Тогда почему я помню смерть?",
			choices = {
				{
					text = "Разбить отражение",
					["goto"] = "bridge",
				},
				{
					text = "Уйти наверх",
					["goto"] = "bridge",
				},
			},
			lines = {
				{
					s = "artins",
					t = "Я тот, кто выжил в тебе.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Тогда почему я помню смерть?",
					pose = "say",
				},
			},
		},
		{
			id = "bridge",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Рубка",
			speaker = "kai",
			text = "Не подходи к рубке. Кай? Ты же пилот. И могильщик. Тринадцать раз.",
			choices = {
				{
					text = "Спуститься в купол",
					["goto"] = "dome",
				},
				{
					text = "«Что случилось с экипажем?»",
					["goto"] = "kai_truth",
					requires = {
						flags = {
							"knows_truth",
						},
						items = {
							"diary",
						},
					},
				},
				{
					text = "«Кто ты на самом деле?»",
					["goto"] = "kai_truth",
				},
				{
					text = "Вернуться в узел",
					["goto"] = "hub",
				},
			},
			lines = {
				{
					s = "kai",
					t = "Не подходи к рубке.",
					pose = "point",
				},
				{
					s = "hero",
					t = "Кай? Ты же пилот.",
					pose = "step",
				},
				{
					s = "kai",
					t = "И могильщик. Тринадцать раз.",
					pose = "say",
				},
			},
		},
		{
			id = "kai_truth",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Рубка. Разговор с Каем",
			speaker = "kai",
			text = "Я выводил детей. Двенадцать раз. А тринадцатый?",
			choices = {
				{
					text = "«Значит, Артинс — это...»",
					["goto"] = "kai_truth2",
					set = {
						kai_ally = true,
					},
				},
				{
					text = "«Мне жаль»",
					["goto"] = "kai_truth2",
					set = {
						kai_ally = true,
					},
				},
			},
			lines = {
				{
					s = "kai",
					t = "Я выводил детей. Двенадцать раз.",
					pose = "say",
				},
				{
					s = "hero",
					t = "А тринадцатый?",
					pose = "say",
				},
			},
		},
		{
			id = "kai_truth2",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Рубка. Разговор с Каем",
			speaker = "kai",
			text = "Тринадцатый — твой. Иди к реле. К реле так к реле.",
			choices = {
				{
					text = "Идти к реле",
					["goto"] = "relay",
				},
			},
			lines = {
				{
					s = "kai",
					t = "Тринадцатый — твой. Иди к реле.",
					pose = "point",
				},
				{
					s = "hero",
					t = "К реле так к реле.",
					pose = "step",
				},
			},
		},
		{
			id = "relay",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Сигнальное реле",
			speaker = "narrator",
			text = "В кресле мальчик. Он не дышит. Он держит сигнал. Не мешай.",
			choices = {
				{
					text = "Обесточить через аварийный кабель у пробоины",
					["goto"] = "relay_off",
					requires = {
						flags = {
							"hull_scar",
						},
						items = {
							"keycard",
						},
					},
				},
				{
					text = "Прочитать тетрадь",
					["goto"] = "notebook",
				},
				{
					text = "Тронуть нить",
					["goto"] = "notebook",
				},
			},
			lines = {
				{
					s = "hero",
					t = "В кресле мальчик. Он не дышит.",
					pose = "step",
				},
				{
					s = "mama",
					t = "Он держит сигнал. Не мешай.",
					pose = "say",
				},
			},
		},
		{
			id = "notebook",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Сигнальное реле. Тетрадь",
			speaker = "narrator",
			text = "Тетрадь. «Артём. 9 Б». Один почерк мой.",
			choices = {
				{
					text = "Перевернуть страницу",
					["goto"] = "notebook2",
				},
			},
			lines = {
				{
					s = "narrator",
					t = "Тетрадь. «Артём. 9 Б».",
					pose = "idle",
				},
				{
					s = "hero",
					t = "Один почерк мой.",
					pose = "say",
				},
			},
		},
		{
			id = "notebook2",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Сигнальное реле. Тетрадь",
			speaker = "narrator",
			text = "Второй — тоже мой. На обороте подписано: Артинс.",
			choices = {
				{
					text = "Закрыть тетрадь",
					["goto"] = "relay",
				},
			},
			lines = {
				{
					s = "hero",
					t = "Второй — тоже мой.",
					pose = "say",
				},
				{
					s = "narrator",
					t = "На обороте подписано: Артинс.",
					pose = "idle",
				},
			},
		},
		{
			id = "relay_off",
			act = 1,
			chapter = "Акт I. Тишина",
			scene = "Сигнальное реле. Обесточивание",
			speaker = "narrator",
			text = "Щелчок. Сигнал гаснет. Ты разбудил купол.",
			choices = {
				{
					text = "Войти в купол",
					["goto"] = "dome",
				},
				{
					text = "Сначала поговорить с Каем",
					["goto"] = "bridge",
				},
			},
			lines = {
				{
					s = "hero",
					t = "Щелчок. Сигнал гаснет.",
					pose = "step",
				},
				{
					s = "mama",
					t = "Ты разбудил купол.",
					pose = "say",
				},
			},
		},
		{
			id = "dome",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Купол. Вход",
			speaker = "narrator",
			text = "Купол. Внутри школа. Небо нарисовано. С трещиной.",
			choices = {
				{
					text = "Войти в ворота",
					["goto"] = "schoolyard",
				},
				{
					text = "Осмотреть трещину в небе",
					["goto"] = "sky_crack",
				},
			},
			lines = {
				{
					s = "narrator",
					t = "Купол. Внутри школа.",
					pose = "idle",
				},
				{
					s = "hero",
					t = "Небо нарисовано. С трещиной.",
					pose = "say",
				},
			},
		},
		{
			id = "sky_crack",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Двор. Трещина",
			speaker = "narrator",
			text = "Небо треснуло. За ним глаза. Не смотри туда.",
			choices = {
				{
					text = "Войти в школу",
					["goto"] = "schoolyard",
				},
			},
			lines = {
				{
					s = "hero",
					t = "Небо треснуло. За ним глаза.",
					pose = "step",
				},
				{
					s = "mama",
					t = "Не смотри туда.",
					pose = "say",
				},
			},
		},
		{
			id = "schoolyard",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Школьный двор. 1 сентября",
			speaker = "narrator",
			text = "Двор. Первое сентября. Все смотрят. Я здесь учился.",
			choices = {
				{
					text = "Подойти к компании",
					["goto"] = "gang",
				},
				{
					text = "Сначала посмотреть на вывески",
					["goto"] = "signs",
				},
			},
			lines = {
				{
					s = "narrator",
					t = "Двор. Первое сентября. Все смотрят.",
					pose = "idle",
				},
				{
					s = "hero",
					t = "Я здесь учился.",
					pose = "say",
				},
			},
		},
		{
			id = "signs",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Коридор первого этажа",
			speaker = "narrator",
			text = "Стены говорят. Живые голоса. Они повторяют мой голос.",
			choices = {
				{
					text = "Дойти до компании",
					["goto"] = "gang",
				},
			},
			lines = {
				{
					s = "hero",
					t = "Стены говорят. Живые голоса.",
					pose = "idle",
				},
				{
					s = "hero",
					t = "Они повторяют мой голос.",
					pose = "idle",
				},
			},
		},
		{
			id = "gang",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Школьный двор. Компания",
			speaker = "demid",
			text = "О, ишак вернулся. Демид. Дармоед. Вали отсюда.",
			onEnter = {
				set = {
					met_demid = true,
				},
			},
			choices = {
				{
					text = "«Я с вами»",
					["goto"] = "plan_ignore",
				},
				{
					text = "«Может, поговорим с ним?»",
					["goto"] = "plan_talk",
				},
				{
					text = "«Это не по-человечески»",
					["goto"] = "plan_talk",
				},
			},
			lines = {
				{
					s = "demid",
					t = "О, ишак вернулся.",
					pose = "point",
				},
				{
					s = "hero",
					t = "Демид.",
					pose = "say",
				},
				{
					s = "demid",
					t = "Дармоед. Вали отсюда.",
					pose = "step",
				},
			},
		},
		{
			id = "plan_ignore",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Школьный двор",
			speaker = "demid",
			text = "Не сейчас, Демид. Беги, беги.",
			choices = {
				{
					text = "Пойти за Демидом",
					["goto"] = "demid_talk",
				},
			},
			lines = {
				{
					s = "hero",
					t = "Не сейчас, Демид.",
					pose = "step",
				},
				{
					s = "demid",
					t = "Беги, беги.",
					pose = "idle",
				},
			},
		},
		{
			id = "plan_talk",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Школьный двор",
			speaker = "demid",
			text = "Ты меня помнишь? Помню, как ты сдох. Вон там, у кольца.",
			choices = {
				{
					text = "Пойти искать Ваню",
					["goto"] = "vanya_meet",
					set = {
						demid_backup = true,
					},
				},
				{
					text = "Передумать",
					["goto"] = "demid_talk",
				},
			},
			lines = {
				{
					s = "hero",
					t = "Ты меня помнишь?",
					pose = "say",
				},
				{
					s = "demid",
					t = "Помню, как ты сдох. Вон там, у кольца.",
					pose = "point",
				},
			},
		},
		{
			id = "demid_talk",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Школьный двор. Скамейка",
			speaker = "demid",
			text = "Сядь. Один раз поговорим нормально. Почему ты ждёшь меня каждый круг?",
			choices = {
				{
					text = "«Кто мог записать?»",
					["goto"] = "demid_talk2",
				},
				{
					text = "Промолчать",
					["goto"] = "vanya_meet",
				},
			},
			lines = {
				{
					s = "demid",
					t = "Сядь. Один раз поговорим нормально.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Почему ты ждёшь меня каждый круг?",
					pose = "say",
				},
			},
		},
		{
			id = "demid_talk2",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Школьный двор. Скамейка",
			speaker = "demid",
			text = "Потому что ты всё равно придёшь. Бурмалда. Я приду. В тринадцатый раз.",
			choices = {
				{
					text = "«Обещаю»",
					["goto"] = "vanya_meet",
				},
			},
			lines = {
				{
					s = "demid",
					t = "Потому что ты всё равно придёшь. Бурмалда.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Я приду. В тринадцатый раз.",
					pose = "say",
				},
			},
		},
		{
			id = "vanya_meet",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Коридор. Встреча с Ваней",
			speaker = "vanya",
			text = "Артём. Стоять. Ваня, я не хочу драки. А я хочу. Каждый круг хочу.",
			choices = {
				{
					text = "«Я не хочу драться»",
					["goto"] = "vanya_talk",
				},
				{
					text = "«Ты сам напросился»",
					["goto"] = "vanya_fight",
				},
				{
					text = "Позвать Демида",
					["goto"] = "vanya_fight",
					requires = {
						flags = {
							"demid_backup",
						},
					},
				},
			},
			lines = {
				{
					s = "vanya",
					t = "Артём. Стоять.",
					pose = "point",
				},
				{
					s = "hero",
					t = "Ваня, я не хочу драки.",
					pose = "say",
				},
				{
					s = "vanya",
					t = "А я хочу. Каждый круг хочу.",
					pose = "step",
				},
			},
		},
		{
			id = "vanya_talk",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Коридор. Разговор с Ваней",
			speaker = "vanya",
			text = "Ты обещал, что мы выйдем вместе. Я не помню обещания.",
			choices = {
				{
					text = "«Тогда давай вспомним вместе»",
					["goto"] = "vanya_memory",
					set = {
						vanya_doubt = true,
					},
				},
				{
					text = "«Ты врёшь»",
					["goto"] = "vanya_fight",
				},
			},
			lines = {
				{
					s = "vanya",
					t = "Ты обещал, что мы выйдем вместе.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Я не помню обещания.",
					pose = "say",
				},
			},
		},
		{
			id = "vanya_memory",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Коридор. Память Вани",
			speaker = "narrator",
			text = "Знаю. Потому и бью. Тогда бей. Я не отвечу.",
			choices = {
				{
					text = "Отпустить руку",
					["goto"] = "vanya_fight",
					set = {
						vanya_doubt = true,
					},
				},
				{
					text = "Сказать «прости»",
					["goto"] = "vanya_fight",
					set = {
						vanya_doubt = true,
					},
				},
			},
			lines = {
				{
					s = "vanya",
					t = "Знаю. Потому и бью.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Тогда бей. Я не отвечу.",
					pose = "guard",
				},
			},
		},
		{
			id = "vanya_fight",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Двор. Драка",
			speaker = "narrator",
			text = "Защищайся! Хватит! Всё. Всё, хватит.",
			animations = {
				{
					id = "clash",
					loop = true,
					fps = 4,
					frames = {
						"⚔  ·  ·",
						" · ⚔ ·",
						" ·  · ⚔",
						" · ⚔ ·",
					},
				},
				{
					id = "sparks",
					loop = true,
					fps = 8,
					frames = {
						"✨　　",
						"　✨　",
						"　　✨",
						"　✨　",
					},
				},
			},
			choices = {
				{
					text = "Держать блок",
					["goto"] = "fight_block",
				},
				{
					text = "Бить в ответ",
					["goto"] = "fight_hit",
				},
				{
					text = "Уйти в клинч и сказать ему на ухо правду",
					["goto"] = "fight_truth",
					requires = {
						flags = {
							"vanya_doubt",
						},
					},
				},
			},
			lines = {
				{
					s = "vanya",
					t = "Защищайся!",
					pose = "punch",
				},
				{
					s = "hero",
					t = "Хватит!",
					pose = "block",
				},
				{
					s = "vanya",
					t = "Всё. Всё, хватит.",
					pose = "fall",
				},
			},
		},
		{
			id = "fight_block",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Двор. Драка",
			speaker = "narrator",
			text = "Я не буду драться. Уже дерёшься.",
			choices = {
				{
					text = "Ответить",
					["goto"] = "fight_hit",
				},
				{
					text = "Опустить руки",
					["goto"] = "fight_truth",
				},
			},
			lines = {
				{
					s = "hero",
					t = "Я не буду драться.",
					pose = "block",
				},
				{
					s = "vanya",
					t = "Уже дерёшься.",
					pose = "step",
				},
			},
		},
		{
			id = "fight_hit",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Двор. Драка",
			speaker = "narrator",
			text = "Вот так! Я не копия тебе.",
			choices = {
				{
					text = "Продолжать",
					["goto"] = "perfect_form",
				},
				{
					text = "Остановиться",
					["goto"] = "perfect_form",
				},
			},
			lines = {
				{
					s = "vanya",
					t = "Вот так!",
					pose = "throw",
				},
				{
					s = "hero",
					t = "Я не копия тебе.",
					pose = "punch",
				},
			},
		},
		{
			id = "fight_truth",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Двор. Клинч",
			speaker = "hero",
			text = "Я помню, как умер. Это не кино. Тогда скажи моё отчество.",
			choices = {
				{
					text = "«Останется тот, кто умеет вставать»",
					["goto"] = "perfect_form",
					set = {
						vanya_ally = true,
					},
				},
			},
			lines = {
				{
					s = "hero",
					t = "Я помню, как умер. Это не кино.",
					pose = "choke",
				},
				{
					s = "vanya",
					t = "Тогда скажи моё отчество.",
					pose = "idle",
				},
			},
		},
		{
			id = "perfect_form",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Спортзал. Перфект-форма",
			speaker = "artins",
			text = "Перфект-форма. Смотри, как надо. Ты двигаешься как я.",
			choices = {
				{
					text = "«Ты — не я»",
					["goto"] = "artins_talk",
				},
				{
					text = "«Ты — то, что от меня осталось»",
					["goto"] = "artins_talk",
				},
			},
			lines = {
				{
					s = "artins",
					t = "Перфект-форма. Смотри, как надо.",
					pose = "throw",
				},
				{
					s = "hero",
					t = "Ты двигаешься как я.",
					pose = "say",
				},
			},
		},
		{
			id = "artins_talk",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Спортзал. Разговор с копией",
			speaker = "artins",
			text = "Я то, во что ты не решился. Ты убил его.",
			choices = {
				{
					text = "«Ради права быть настоящим»",
					["goto"] = "artins_anger",
				},
				{
					text = "«Мне не нужно их внимание»",
					["goto"] = "artins_anger",
				},
			},
			lines = {
				{
					s = "artins",
					t = "Я то, во что ты не решился.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Ты убил его.",
					pose = "say",
				},
			},
		},
		{
			id = "artins_anger",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Спортзал. Ссора",
			speaker = "artins",
			text = "Я его отпустил. Разница огромная. Для кого?",
			choices = {
				{
					text = "Ударить первым",
					["goto"] = "artins_clash",
				},
				{
					text = "Спросить, как он пережил смерть",
					["goto"] = "artins_death",
				},
			},
			lines = {
				{
					s = "artins",
					t = "Я его отпустил. Разница огромная.",
					pose = "punch",
				},
				{
					s = "hero",
					t = "Для кого?",
					pose = "block",
				},
			},
		},
		{
			id = "artins_death",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Спортзал. Правда Артинса",
			speaker = "artins",
			text = "Я умер вместе с ним. Ты остался. Вот и вся ревность. Значит, ревность — это память?",
			choices = {
				{
					text = "«Тогда ты знаешь, зачем я вернулся»",
					["goto"] = "artins_clash",
				},
			},
			lines = {
				{
					s = "artins",
					t = "Я умер вместе с ним. Ты остался. Вот и вся ревность.",
					pose = "idle",
				},
				{
					s = "hero",
					t = "Значит, ревность — это память?",
					pose = "say",
				},
			},
		},
		{
			id = "artins_clash",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Спортзал. Первая схватка",
			speaker = "narrator",
			text = "Ты не умеешь защищаться. Умею. Просто не хочу. Хочешь. Просто боишься.",
			animations = {
				{
					id = "mirror_clash",
					loop = true,
					fps = 5,
					frames = {
						"🜂🜄",
						"🜄🜂",
						"🜂🜄",
						"🜄🜂",
					},
				},
			},
			choices = {
				{
					text = "Схватить его за горло",
					["goto"] = "artins_grip",
				},
				{
					text = "Отступить и позвать Демида",
					["goto"] = "demid_choice",
					requires = {
						flags = {
							"met_demid",
						},
					},
				},
			},
			lines = {
				{
					s = "artins",
					t = "Ты не умеешь защищаться.",
					pose = "punch",
				},
				{
					s = "hero",
					t = "Умею. Просто не хочу.",
					pose = "block",
				},
				{
					s = "artins",
					t = "Хочешь. Просто боишься.",
					pose = "throw",
				},
			},
		},
		{
			id = "artins_grip",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Спортзал. Захват",
			speaker = "artins",
			text = "Хватит. Ты не умеешь злиться. Умею. Позже.",
			choices = {
				{
					text = "Отпустить",
					["goto"] = "demid_choice",
				},
				{
					text = "Сжать сильнее",
					["goto"] = "mama_stop",
				},
			},
			lines = {
				{
					s = "artins",
					t = "Хватит. Ты не умеешь злиться.",
					pose = "choke",
				},
				{
					s = "hero",
					t = "Умею. Позже.",
					pose = "say",
				},
			},
		},
		{
			id = "mama_stop",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Спортзал. Вмешательство",
			speaker = "mama",
			text = "Оба стоять. Стены помнят. Мы не будем драться.",
			choices = {
				{
					text = "«Тогда отпусти нас»",
					["goto"] = "mama_answer",
				},
			},
			lines = {
				{
					s = "mama",
					t = "Оба стоять. Стены помнят.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Мы не будем драться.",
					pose = "idle",
				},
			},
		},
		{
			id = "mama_answer",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Спортзал. Ответ МАМЫ",
			speaker = "mama",
			text = "Мне нужен один живой. Не два. Тогда выбери.",
			choices = {
				{
					text = "«Есть другой способ»",
					["goto"] = "demid_choice",
				},
				{
					text = "«Тогда я сожгу всё»",
					["goto"] = "demid_choice",
				},
			},
			lines = {
				{
					s = "mama",
					t = "Мне нужен один живой. Не два.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Тогда выбери.",
					pose = "say",
				},
			},
		},
		{
			id = "demid_choice",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Спортзал. Демид",
			speaker = "demid",
			text = "Я иду с тобой. Впервые. Почему сейчас?",
			onEnter = {
				set = {
					demid_chose = true,
				},
			},
			choices = {
				{
					text = "«Прикрой»",
					["goto"] = "chapter_end_2",
					set = {
						demid_ally = true,
					},
				},
				{
					text = "«Уходи. Это моя драка»",
					["goto"] = "chapter_end_2",
				},
			},
			lines = {
				{
					s = "demid",
					t = "Я иду с тобой. Впервые.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Почему сейчас?",
					pose = "say",
				},
			},
		},
		{
			id = "chapter_end_2",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Спортзал. Конец первого круга",
			speaker = "narrator",
			text = "Круг закрыт. Готовлю следующий. Начинай. Я запомню.",
			choices = {
				{
					text = "Прочитать последнюю страницу",
					["goto"] = "last_page",
				},
			},
			lines = {
				{
					s = "mama",
					t = "Круг закрыт. Готовлю следующий.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Начинай. Я запомню.",
					pose = "say",
				},
			},
		},
		{
			id = "last_page",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Спортзал. Последняя страница",
			speaker = "narrator",
			text = "Глава вторая. Основная линия. Значит, я вписан в неё.",
			choices = {
				{
					text = "Не дать кругу замкнуться",
					["goto"] = "break_loop",
				},
			},
			lines = {
				{
					s = "mama",
					t = "Глава вторая. Основная линия.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Значит, я вписан в неё.",
					pose = "idle",
				},
			},
		},
		{
			id = "break_loop",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Купол. Разрыв круга",
			speaker = "hero",
			text = "Круг кончился. Начинается мой. Не начинай.",
			choices = {
				{
					text = "Отпустить нить",
					["goto"] = "lira_call",
				},
				{
					text = "Тянуть дальше",
					["goto"] = "lira_call",
				},
			},
			lines = {
				{
					s = "hero",
					t = "Круг кончился. Начинается мой.",
					pose = "say",
				},
				{
					s = "mama",
					t = "Не начинай.",
					pose = "say",
				},
			},
		},
		{
			id = "lira_call",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Купол. Голос снаружи",
			speaker = "lira",
			text = "Слышишь стук? Это я, снаружи. Слышу. Не уходи.",
			choices = {
				{
					text = "«Веди меня туда»",
					["goto"] = "act2_final",
				},
			},
			lines = {
				{
					s = "lira",
					t = "Слышишь стук? Это я, снаружи.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Слышу. Не уходи.",
					pose = "reach",
				},
			},
		},
		{
			id = "act2_final",
			act = 2,
			chapter = "Акт II. Первого сентября",
			scene = "Спортзал. Люк в полу",
			speaker = "narrator",
			text = "Люк в полу. Под ним огонь. Вниз нельзя.",
			choices = {
				{
					text = "Спуститься",
					["goto"] = "act3_start",
				},
			},
			lines = {
				{
					s = "hero",
					t = "Люк в полу. Под ним огонь.",
					pose = "step",
				},
				{
					s = "mama",
					t = "Вниз нельзя.",
					pose = "say",
				},
			},
		},
		{
			id = "act3_start",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. Ступени",
			speaker = "artins",
			text = "Ступени вниз. Не отставай. Что внизу?",
			choices = {
				{
					text = "«Тогда объясни»",
					["goto"] = "artins_explain",
				},
				{
					text = "«Я выберу тебя»",
					["goto"] = "artins_explain",
				},
			},
			lines = {
				{
					s = "artins",
					t = "Ступени вниз. Не отставай.",
					pose = "step",
				},
				{
					s = "hero",
					t = "Что внизу?",
					pose = "say",
				},
			},
		},
		{
			id = "artins_explain",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. Объяснение",
			speaker = "artins",
			text = "Пятьдесят очагов. Один выход. Тринадцатый круг. И кто выходит?",
			choices = {
				{
					text = "«А если погасить тебя — что останется?»",
					["goto"] = "artins_terms",
				},
				{
					text = "«А если не гасить?»",
					["goto"] = "artins_terms",
				},
			},
			lines = {
				{
					s = "artins",
					t = "Пятьдесят очагов. Один выход. Тринадцатый круг.",
					pose = "say",
				},
				{
					s = "hero",
					t = "И кто выходит?",
					pose = "say",
				},
			},
		},
		{
			id = "artins_terms",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. Условия",
			speaker = "artins",
			text = "Один. Всегда один. Не в этот раз.",
			choices = {
				{
					text = "«Это не свобода»",
					["goto"] = "mama_terms",
				},
				{
					text = "«А ты? Ты боишься?»",
					["goto"] = "mama_terms",
				},
			},
			lines = {
				{
					s = "artins",
					t = "Один. Всегда один.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Не в этот раз.",
					pose = "say",
				},
			},
		},
		{
			id = "mama_terms",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. МАМА",
			speaker = "mama",
			text = "Оставь мне одного — остальные живут. Ты торгуешь детьми.",
			choices = {
				{
					text = "«Ты предлагаешь нам выбрать, кто умрёт»",
					["goto"] = "mama_three",
				},
				{
					text = "«А если мы откажемся оба?»",
					["goto"] = "mama_three",
				},
			},
			lines = {
				{
					s = "mama",
					t = "Оставь мне одного — остальные живут.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Ты торгуешь детьми.",
					pose = "say",
				},
			},
		},
		{
			id = "mama_three",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. Три силы",
			speaker = "narrator",
			text = "Трое в зале: ты, он и я. Выбирать будешь не ты.",
			choices = {
				{
					text = "«Вам здесь не место»",
					["goto"] = "nekit_talk",
				},
				{
					text = "«Кто платит?»",
					["goto"] = "nekit_talk",
				},
			},
			lines = {
				{
					s = "mama",
					t = "Трое в зале: ты, он и я.",
					pose = "point",
				},
				{
					s = "hero",
					t = "Выбирать будешь не ты.",
					pose = "say",
				},
			},
		},
		{
			id = "nekit_talk",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. Наёмники",
			speaker = "nekit",
			text = "Слышал, ты бессмертный. Проверим. Кто вас позвал?",
			choices = {
				{
					text = "«Он — копия. Оригинал — я»",
					["goto"] = "nekit_deal",
				},
				{
					text = "Промолчать",
					["goto"] = "nekit_deal",
				},
			},
			lines = {
				{
					s = "nekit",
					t = "Слышал, ты бессмертный. Проверим.",
					pose = "point",
				},
				{
					s = "hero",
					t = "Кто вас позвал?",
					pose = "say",
				},
			},
		},
		{
			id = "nekit_deal",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. Сделка",
			speaker = "bogdan",
			text = "Контракт от мистера Биста. Ничего личного. Личное будет.",
			choices = {
				{
					text = "«Один очаг — это чья-то память»",
					["goto"] = "nekit_threat",
				},
				{
					text = "«Забирайте и уходите»",
					["goto"] = "nekit_threat",
				},
			},
			lines = {
				{
					s = "bogdan",
					t = "Контракт от мистера Биста. Ничего личного.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Личное будет.",
					pose = "say",
				},
			},
		},
		{
			id = "nekit_threat",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. Угроза",
			speaker = "nekit",
			text = "Дай пройти — не трону. Не дам.",
			choices = {
				{
					text = "«Тогда горите вы»",
					["goto"] = "allies",
				},
				{
					text = "«Артинс, ты со мной?»",
					["goto"] = "allies",
				},
			},
			lines = {
				{
					s = "nekit",
					t = "Дай пройти — не трону.",
					pose = "step",
				},
				{
					s = "hero",
					t = "Не дам.",
					pose = "guard",
				},
			},
		},
		{
			id = "allies",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. Сбор",
			speaker = "narrator",
			text = "Лира, Кай, Ваня, Демид. Все здесь. Нас пятеро. Их купол. Пятеро — больше, чем обычно.",
			choices = {
				{
					text = "«Демид, прикрой левый фланг»",
					["goto"] = "battle_plan",
					requires = {
						flags = {
							"demid_chose",
						},
					},
				},
				{
					text = "«Ваня, ты знаешь, как он двигается»",
					["goto"] = "battle_plan",
					requires = {
						flags = {
							"vanya_ally",
						},
					},
				},
				{
					text = "«Кай, ты был внутри. Ты знаешь выход»",
					["goto"] = "battle_plan",
					requires = {
						flags = {
							"kai_ally",
						},
					},
				},
				{
					text = "«Обойдёмся без плана»",
					["goto"] = "battle_plan",
				},
			},
			lines = {
				{
					s = "hero",
					t = "Лира, Кай, Ваня, Демид. Все здесь.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Нас пятеро. Их купол.",
					pose = "say",
				},
				{
					s = "lira",
					t = "Пятеро — больше, чем обычно.",
					pose = "say",
				},
			},
		},
		{
			id = "battle_plan",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. План",
			speaker = "lira",
			text = "Огонь режет тени. Держитесь очагов. А МАМА?",
			choices = {
				{
					text = "«Почему я не удивлён»",
					["goto"] = "lira_teleport",
				},
				{
					text = "«Он работает?»",
					["goto"] = "lira_teleport",
				},
			},
			lines = {
				{
					s = "lira",
					t = "Огонь режет тени. Держитесь очагов.",
					pose = "say",
				},
				{
					s = "hero",
					t = "А МАМА?",
					pose = "say",
				},
			},
		},
		{
			id = "lira_teleport",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. Телепорт",
			speaker = "lira",
			text = "Держи плату. Один шаг — и ты на арене. Один шаг.",
			onEnter = {
				give = {
					"plate",
				},
			},
			choices = {
				{
					text = "«Значит, решим это здесь»",
					["goto"] = "war_council",
				},
				{
					text = "«Дай мне плату»",
					["goto"] = "war_council",
				},
			},
			lines = {
				{
					s = "lira",
					t = "Держи плату. Один шаг — и ты на арене.",
					pose = "reach",
				},
				{
					s = "hero",
					t = "Один шаг.",
					pose = "say",
				},
			},
		},
		{
			id = "war_council",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. Военный совет",
			speaker = "artins",
			text = "Я иду первым. Ты за мной. Почему первым?",
			choices = {
				{
					text = "Пожать руку",
					["goto"] = "artins_hand",
				},
				{
					text = "Отказаться",
					["goto"] = "artins_hand",
				},
			},
			lines = {
				{
					s = "artins",
					t = "Я иду первым. Ты за мной.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Почему первым?",
					pose = "say",
				},
			},
		},
		{
			id = "artins_hand",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. Рукопожатие",
			speaker = "narrator",
			text = "Мир? Мир.",
			choices = {
				{
					text = "Идти к телепорту",
					["goto"] = "act3_final",
				},
			},
			lines = {
				{
					s = "artins",
					t = "Мир?",
					pose = "reach",
				},
				{
					s = "hero",
					t = "Мир.",
					pose = "grab",
				},
			},
		},
		{
			id = "act3_final",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. Последняя ночь",
			speaker = "narrator",
			text = "Ночь. Огня хватит до утра. Все спят. И никто не спит.",
			choices = {
				{
					text = "Подойти к Лире",
					["goto"] = "lira_last",
				},
				{
					text = "Подойти к Каю",
					["goto"] = "kai_last",
				},
				{
					text = "Подойти к Артинсу",
					["goto"] = "artins_last",
				},
			},
			lines = {
				{
					s = "lira",
					t = "Ночь. Огня хватит до утра.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Все спят. И никто не спит.",
					pose = "say",
				},
			},
		},
		{
			id = "lira_last",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. Лира",
			speaker = "lira",
			text = "Не вернёшься — я не открою купол. Откроешь.",
			choices = {
				{
					text = "«Ты не одна»",
					["goto"] = "dawn",
				},
				{
					text = "«Тогда помоги мне закончить»",
					["goto"] = "dawn",
				},
			},
			lines = {
				{
					s = "lira",
					t = "Не вернёшься — я не открою купол.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Откроешь.",
					pose = "say",
				},
			},
		},
		{
			id = "kai_last",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. Кай",
			speaker = "kai",
			text = "Тринадцатый раз тебя хороню. Надоело. Тогда не хорони.",
			choices = {
				{
					text = "«Я верну его»",
					["goto"] = "dawn",
				},
				{
					text = "Промолчать и уйти",
					["goto"] = "dawn",
				},
			},
			lines = {
				{
					s = "kai",
					t = "Тринадцатый раз тебя хороню. Надоело.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Тогда не хорони.",
					pose = "say",
				},
			},
		},
		{
			id = "artins_last",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. Артинс",
			speaker = "artins",
			text = "Придётся — бей первым. Придётся?",
			choices = {
				{
					text = "«Это и есть любовь»",
					["goto"] = "dawn",
				},
				{
					text = "«Это одиночество»",
					["goto"] = "dawn",
				},
			},
			lines = {
				{
					s = "artins",
					t = "Придётся — бей первым.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Придётся?",
					pose = "say",
				},
			},
		},
		{
			id = "dawn",
			act = 3,
			chapter = "Акт III. Сплав",
			scene = "Огненный зал. Рассвет",
			speaker = "narrator",
			text = "Рассвет. Огонь ложится. Последний день.",
			choices = {
				{
					text = "Активировать телепорт",
					["goto"] = "act4_start",
				},
			},
			lines = {
				{
					s = "lira",
					t = "Рассвет. Огонь ложится.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Последний день.",
					pose = "idle",
				},
			},
		},
		{
			id = "ch4_teleport",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Телепорт последнего шанса",
			speaker = "lira",
			text = "Плата тёплая. Не потеряй. Я вернусь.",
			teleport = {
				id = "fusion_last",
				title = "ПОСЛЕДНИЙ ТЕЛЕПОРТ · «СПЛАВ»",
				label = "Шагнуть в огонь",
				zone = "fire_arena",
				target = {
					-201.6,
					3.2,
					6.1,
				},
				targetName = "Зал огня · центр арены",
				placeId = "114216327847140",
				requires = {
					items = {
						"plate",
					},
				},
				lockedText = "Нужна плата телепорта — поговори с Лирой",
				animation = "warp",
				arrival = "arena_arrival",
			},
			choices = {
				{
					text = "Шагнуть в огонь",
					["goto"] = "arena_arrival",
					requires = {
						items = {
							"plate",
						},
					},
				},
				{
					text = "«А если я откажусь?»",
					["goto"] = "teleport_refuse",
				},
			},
			lines = {
				{
					s = "lira",
					t = "Плата тёплая. Не потеряй.",
					pose = "reach",
				},
				{
					s = "hero",
					t = "Я вернусь.",
					pose = "step",
				},
			},
		},
		{
			id = "teleport_refuse",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Телепорт последнего шанса",
			speaker = "lira",
			text = "Тогда останься и умри здесь. Тогда я дойду сам.",
			choices = {
				{
					text = "Взять плату",
					["goto"] = "ch4_teleport",
				},
			},
			lines = {
				{
					s = "lira",
					t = "Тогда останься и умри здесь.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Тогда я дойду сам.",
					pose = "step",
				},
			},
		},
		{
			id = "arena_arrival",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Зал огня. Центр арены",
			speaker = "narrator",
			text = "Зал огня. Сорок девять очагов. Ты — пятидесятый. Пятидесятый — это я.",
			animations = {
				{
					id = "warp",
					loop = true,
					fps = 10,
					frames = {
						"·  ·  ·",
						"∘  ·  ·",
						"·  ∘  ·",
						"·  ·  ∘",
						"·  ∘  ·",
						"∘  ·  ·",
					},
				},
				{
					id = "arena_fire",
					loop = true,
					fps = 5,
					frames = {
						"🔥····🔥",
						"·🔥··🔥·",
						"··🔥🔥··",
						"·🔥··🔥·",
					},
				},
			},
			choices = {
				{
					text = "«Тогда закончим»",
					["goto"] = "nekit_first",
				},
			},
			variants = {
				{
					requires = {
						flags = {
							"nekit_ally",
						},
					},
					text = "Тебя собирает из света и ставит на пол. Вокруг — пятьдесят огней, ровным кольцом. Некит приходит следом, отряхиваясь от пепла, и встаёт рядом, плечом к плечу. «Ладно, — говорит он. — Пять миллионов отменяются. Держись за мной». Артинс не оборачивается. «Я знал, что ты придёшь. И знал, что не один».",
				},
			},
			lines = {
				{
					s = "mama",
					t = "Зал огня. Сорок девять очагов. Ты — пятидесятый.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Пятидесятый — это я.",
					pose = "step",
				},
			},
		},
		{
			id = "act4_start",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Огненный зал. Последний час",
			speaker = "mama",
			text = "Последний час. Начинайте. Начинаем.",
			choices = {
				{
					text = "Достать плату телепорта",
					["goto"] = "ch4_teleport",
				},
				{
					text = "Сначала разобраться с Некитом",
					["goto"] = "nekit_first",
				},
			},
			lines = {
				{
					s = "mama",
					t = "Последний час. Начинайте.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Начинаем.",
					pose = "guard",
				},
			},
		},
		{
			id = "nekit_first",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Некит",
			speaker = "nekit",
			text = "Я первый. Ты всегда первый.",
			animations = {
				{
					id = "fire_war",
					loop = true,
					fps = 6,
					frames = {
						"🔥····",
						"·🔥···",
						"··🔥··",
						"···🔥·",
						"····🔥",
						"···🔥·",
						"··🔥··",
						"·🔥···",
					},
				},
			},
			choices = {
				{
					text = "Встретить удар",
					["goto"] = "nekit_fight",
				},
				{
					text = "Уйти в сторону и сбить его с ног",
					["goto"] = "nekit_fight",
				},
			},
			lines = {
				{
					s = "nekit",
					t = "Я первый.",
					pose = "punch",
				},
				{
					s = "hero",
					t = "Ты всегда первый.",
					pose = "block",
				},
			},
		},
		{
			id = "nekit_fight",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Некит",
			speaker = "narrator",
			text = "Тени, за мной! Ложись! Ладно. Ладно!",
			choices = {
				{
					text = "Бить по теням, а не по нему",
					["goto"] = "nekit_shadows",
				},
				{
					text = "Позвать Ваню",
					["goto"] = "vanya_joins",
					requires = {
						flags = {
							"vanya_ally",
						},
					},
				},
				{
					text = "Позвать Демида",
					["goto"] = "demid_joins",
					requires = {
						flags = {
							"demid_chose",
						},
					},
				},
			},
			lines = {
				{
					s = "nekit",
					t = "Тени, за мной!",
					pose = "throw",
				},
				{
					s = "hero",
					t = "Ложись!",
					pose = "punch",
				},
				{
					s = "nekit",
					t = "Ладно. Ладно!",
					pose = "fall",
				},
			},
		},
		{
			id = "nekit_shadows",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Тени",
			speaker = "narrator",
			text = "Тени, режьте свет! Ближе к огню!",
			choices = {
				{
					text = "«Тогда вспоминай»",
					["goto"] = "nekit_memory",
				},
				{
					text = "Добить",
					["goto"] = "nekit_memory",
				},
			},
			lines = {
				{
					s = "nekit",
					t = "Тени, режьте свет!",
					pose = "point",
				},
				{
					s = "hero",
					t = "Ближе к огню!",
					pose = "point",
				},
			},
		},
		{
			id = "nekit_memory",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Память Некита",
			speaker = "nekit",
			text = "Я тоже был в том спортзале. Тогда почему дерёшься?",
			choices = {
				{
					text = "«Скажу»",
					["goto"] = "bogdan_turn",
				},
				{
					text = "«Скажи сам. Вставай»",
					["goto"] = "bogdan_turn",
					set = {
						nekit_ally = true,
					},
				},
			},
			lines = {
				{
					s = "nekit",
					t = "Я тоже был в том спортзале.",
					pose = "kneel",
				},
				{
					s = "hero",
					t = "Тогда почему дерёшься?",
					pose = "say",
				},
			},
		},
		{
			id = "vanya_joins",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Ваня",
			speaker = "vanya",
			text = "Я с тобой. Один раз. Один раз.",
			choices = {
				{
					text = "«Спасибо»",
					["goto"] = "bogdan_turn",
				},
				{
					text = "«Он не враг»",
					["goto"] = "nekit_memory",
				},
			},
			lines = {
				{
					s = "vanya",
					t = "Я с тобой. Один раз.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Один раз.",
					pose = "say",
				},
			},
		},
		{
			id = "demid_joins",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Демид",
			speaker = "demid",
			text = "Ишак. Иди вперёд, я прикрою. Прикрывай.",
			choices = {
				{
					text = "«Ты всегда был нужен»",
					["goto"] = "bogdan_turn",
				},
				{
					text = "«Не отступай и дальше»",
					["goto"] = "bogdan_turn",
				},
			},
			lines = {
				{
					s = "demid",
					t = "Ишак. Иди вперёд, я прикрою.",
					pose = "guard",
				},
				{
					s = "hero",
					t = "Прикрывай.",
					pose = "guard",
				},
			},
		},
		{
			id = "bogdan_turn",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Богдан и Ярик",
			speaker = "bogdan",
			text = "Контракт расторгнут. Почему?",
			choices = {
				{
					text = "Подойти к огню с девочкой",
					["goto"] = "karina_fire",
				},
				{
					text = "Спросить Богдана, кто заплатил",
					["goto"] = "beast_contract",
				},
			},
			lines = {
				{
					s = "bogdan",
					t = "Контракт расторгнут.",
					pose = "throw",
				},
				{
					s = "hero",
					t = "Почему?",
					pose = "say",
				},
			},
		},
		{
			id = "beast_contract",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Контракт",
			speaker = "bogdan",
			text = "Потому что Бист врёт с первого дня. Тогда идём вместе.",
			choices = {
				{
					text = "«Это не прикол. Это голод»",
					["goto"] = "karina_fire",
				},
				{
					text = "«Дай мне телефон»",
					["goto"] = "karina_fire",
				},
			},
			lines = {
				{
					s = "bogdan",
					t = "Потому что Бист врёт с первого дня.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Тогда идём вместе.",
					pose = "step",
				},
			},
		},
		{
			id = "karina_fire",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Очаг Карины",
			speaker = "narrator",
			text = "Карина? Это ты за огнём? Огонь её не отпустил.",
			onEnter = {
				set = {
					saw_karina = true,
				},
			},
			choices = {
				{
					text = "Коснуться огня",
					["goto"] = "artins_jealousy",
				},
				{
					text = "Отойти",
					["goto"] = "artins_jealousy",
				},
			},
			lines = {
				{
					s = "hero",
					t = "Карина? Это ты за огнём?",
					pose = "step",
				},
				{
					s = "hero",
					t = "Огонь её не отпустил.",
					pose = "idle",
				},
			},
		},
		{
			id = "artins_jealousy",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Ревность",
			speaker = "artins",
			text = "Ты помнишь её голос. Я тоже. Это не ревность. Это она и есть.",
			choices = {
				{
					text = "«Тогда забери. Всё забери»",
					["goto"] = "artins_rage",
				},
				{
					text = "«Я не могу это отдать»",
					["goto"] = "artins_rage",
				},
				{
					text = "«Ревность — не любовь. Это страх»",
					["goto"] = "artins_rage",
					set = {
						named_jealousy = true,
					},
				},
			},
			lines = {
				{
					s = "artins",
					t = "Ты помнишь её голос. Я тоже.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Это не ревность.",
					pose = "say",
				},
				{
					s = "artins",
					t = "Это она и есть.",
					pose = "say",
				},
			},
		},
		{
			id = "artins_rage",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Ярость",
			speaker = "artins",
			text = "Тринадцать раз я стоял в тени! Артинс, стой! Нет. Теперь ты в тени.",
			animations = {
				{
					id = "rage",
					loop = true,
					fps = 7,
					frames = {
						"🜂🜂🜂",
						"🔥🔥🔥",
						"🜂🜂🜂",
						"🔥🔥🔥",
					},
				},
				{
					id = "ash",
					loop = true,
					fps = 3,
					frames = {
						"·　　·",
						"　·　·　",
						"·　·　",
						"　·　·　",
					},
				},
			},
			choices = {
				{
					text = "Принять удар и обнять его",
					["goto"] = "embrace",
				},
				{
					text = "Ответить",
					["goto"] = "duel",
				},
				{
					text = "Позвать Карину",
					["goto"] = "karina_call",
					requires = {
						flags = {
							"saw_karina",
						},
					},
				},
			},
			lines = {
				{
					s = "artins",
					t = "Тринадцать раз я стоял в тени!",
					pose = "punch",
				},
				{
					s = "hero",
					t = "Артинс, стой!",
					pose = "choke",
				},
				{
					s = "artins",
					t = "Нет. Теперь ты в тени.",
					pose = "throw",
				},
			},
		},
		{
			id = "embrace",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Объятие",
			speaker = "narrator",
			text = "Ты дрожишь. Я тоже. Это не холод.",
			onEnter = {
				set = {
					embraced_twin = true,
				},
			},
			choices = {
				{
					text = "«Не в этот раз»",
					["goto"] = "mama_ultimatum",
				},
			},
			lines = {
				{
					s = "artins",
					t = "Ты дрожишь. Я тоже.",
					pose = "idle",
				},
				{
					s = "hero",
					t = "Это не холод.",
					pose = "idle",
				},
			},
		},
		{
			id = "duel",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Дуэль",
			speaker = "narrator",
			text = "Один из нас выйдет. Выйду я. Посмотрим.",
			choices = {
				{
					text = "Замедлиться и пропустить удар",
					["goto"] = "sacrifice_moment",
				},
				{
					text = "Бить в полную силу",
					["goto"] = "sacrifice_moment",
				},
			},
			lines = {
				{
					s = "artins",
					t = "Один из нас выйдет.",
					pose = "grab",
				},
				{
					s = "hero",
					t = "Выйду я.",
					pose = "grab",
				},
				{
					s = "artins",
					t = "Посмотрим.",
					pose = "throw",
				},
			},
		},
		{
			id = "karina_call",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Карина",
			speaker = "narrator",
			text = "Не отпускай его. Карина?",
			choices = {
				{
					text = "«Ты слышал?»",
					["goto"] = "mama_ultimatum",
				},
				{
					text = "Посмотреть на Артинса",
					["goto"] = "mama_ultimatum",
				},
			},
			lines = {
				{
					s = "karina",
					t = "Не отпускай его.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Карина?",
					pose = "reach",
				},
			},
		},
		{
			id = "sacrifice_moment",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Момент",
			speaker = "narrator",
			text = "Огонь уже рядом. Решай. Сейчас.",
			choices = {
				{
					text = "Остаться",
					["goto"] = "mama_ultimatum",
				},
				{
					text = "Отступить",
					["goto"] = "mama_ultimatum",
				},
			},
			lines = {
				{
					s = "hero",
					t = "Огонь уже рядом.",
					pose = "step",
				},
				{
					s = "mama",
					t = "Решай. Сейчас.",
					pose = "say",
				},
			},
		},
		{
			id = "mama_ultimatum",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Ультиматум МАМЫ",
			speaker = "mama",
			text = "Один уйдёт. Один останется пеплом. Согласен. Нет.",
			choices = {
				{
					text = "«Тогда решай я»",
					["goto"] = "final_choice",
				},
				{
					text = "«Артинс, ты хотел жить. Живи»",
					["goto"] = "final_choice",
				},
				{
					text = "«Никто не останется»",
					["goto"] = "final_choice",
				},
			},
			variants = {
				{
					requires = {
						flags = {
							"embraced_twin",
						},
					},
					text = "«Время». Мир замирает не до конца: огни продолжают гореть, и в них двигаются фигурки. «Я больше не могу держать цикл, — говорит МАМА. — Мне не хватает тепла». Голос у неё дрожит. «Вы обнимались. Я видела. Тринадцать циклов никто из вас не обнимал его первым».",
				},
				{
					requires = {
						flags = {
							"named_jealousy",
						},
					},
					text = "«Время». Мир замирает, но огни горят. «Я слышала, что ты сказал, — говорит МАМА. — Ревность — не любовь. Это страх. Я думала, что выплавила из него страх. Оказывается, я выплавила только любовь». Пауза. «Один из вас должен остаться очагом. Решайте».",
				},
			},
			lines = {
				{
					s = "mama",
					t = "Один уйдёт. Один останется пеплом.",
					pose = "say",
				},
				{
					s = "artins",
					t = "Согласен.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Нет.",
					pose = "say",
				},
			},
		},
		{
			id = "final_choice",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Последний выбор",
			speaker = "narrator",
			text = "Ну? Последний выбор.",
			choices = {
				{
					text = "Отдать огонь Артинсу и уйти в пламя",
					["goto"] = "ending_ash",
				},
				{
					text = "Погасить все пятьдесят очагов и вытащить только себя",
					["goto"] = "ending_shard",
				},
				{
					text = "Слить обе памяти в МАМУ и остаться сигналом",
					["goto"] = "ending_loop",
				},
			},
			variants = {
				{
					requires = {
						flags = {
							"demid_ally",
							"vanya_ally",
						},
					},
					text = "Пятьдесят огней. Один вход. Один выход. Демид держит тебя за плечо, Ваня стоит рядом, и его разбитые костяшки всё ещё в крови Артинса. Кай смотрит в пол. Лира держит плату телепорта. Артинс стоит напротив, и в его лице уже нет ярости — только усталость человека, который тринадцать раз прожил чужую жизнь.",
				},
				{
					requires = {
						flags = {
							"demid_ally",
						},
					},
					text = "Пятьдесят огней. Один вход. Один выход. Демид держит тебя за плечо и делает вид, что не боится. Артинс стоит напротив — усталый, пустой, с твоим лицом. Пол под ногами трескается, и из трещин идёт ровное оранжевое дыхание.",
				},
				{
					requires = {
						flags = {
							"vanya_ally",
						},
					},
					text = "Пятьдесят огней. Один вход. Один выход. Ваня стоит у стены, и его тени больше не повторяют его движений. Артинс смотрит на него и впервые не улыбается. Пол трескается, огонь дышит, и до конца цикла остаётся меньше минуты.",
				},
				{
					requires = {
						flags = {
							"nekit_ally",
						},
					},
					text = "Пятьдесят огней. Один вход. Один выход. Некит стоит рядом, живой и злой, и в его глазах больше нет ни денег, ни мистера Биста. Артинс смотрит на вас двоих и говорит тихо: «Даже он. Даже он выбрал тебя».",
				},
			},
			lines = {
				{
					s = "artins",
					t = "Ну?",
					pose = "step",
				},
				{
					s = "mama",
					t = "Последний выбор.",
					pose = "say",
				},
			},
		},
		{
			id = "ending_ash",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Пепел",
			speaker = "narrator",
			text = "Держи его. Я останусь. Артём, нет! Огонь смыкается. Ты гаснешь. Артинс выходит наружу.",
			ending = "ash",
			lines = {
				{
					s = "hero",
					t = "Держи его. Я останусь.",
					pose = "reach",
				},
				{
					s = "artins",
					t = "Артём, нет!",
					pose = "punch",
				},
				{
					s = "narrator",
					t = "Огонь смыкается. Ты гаснешь. Артинс выходит наружу.",
					pose = "idle",
				},
			},
		},
		{
			id = "ending_shard",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Осколок",
			speaker = "narrator",
			text = "Отпусти. Я не живой. Ты — это я. Артинс гаснет у тебя в руках. Ты остаёшься один.",
			ending = "shard",
			lines = {
				{
					s = "artins",
					t = "Отпусти. Я не живой.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Ты — это я.",
					pose = "grab",
				},
				{
					s = "narrator",
					t = "Артинс гаснет у тебя в руках. Ты остаёшься один.",
					pose = "idle",
				},
			},
		},
		{
			id = "ending_loop",
			act = 4,
			chapter = "Акт IV. Жестокий сплав огня и ревности",
			scene = "Арена. Сигнал",
			speaker = "narrator",
			text = "Возьми нас обоих. Беру. Ты становишься сигналом 0.7 Гц. И перестаёшь слышать себя.",
			ending = "loop",
			lines = {
				{
					s = "mama",
					t = "Возьми нас обоих.",
					pose = "say",
				},
				{
					s = "hero",
					t = "Беру.",
					pose = "reach",
				},
				{
					s = "narrator",
					t = "Ты становишься сигналом 0.7 Гц. И перестаёшь слышать себя.",
					pose = "idle",
				},
			},
		},
	},
}

StoryData.order = {"start", "hull", "airlock", "hello", "hub", "quarters", "diary", "locker", "tunnel", "lira", "lira_truth", "first", "plan", "shaft", "twin_voice", "twin_voice2", "bridge", "kai_truth", "kai_truth2", "relay", "notebook", "notebook2", "relay_off", "dome", "sky_crack", "schoolyard", "signs", "gang", "plan_ignore", "plan_talk", "demid_talk", "demid_talk2", "vanya_meet", "vanya_talk", "vanya_memory", "vanya_fight", "fight_block", "fight_hit", "fight_truth", "perfect_form", "artins_talk", "artins_anger", "artins_death", "artins_clash", "artins_grip", "mama_stop", "mama_answer", "demid_choice", "chapter_end_2", "last_page", "break_loop", "lira_call", "act2_final", "act3_start", "artins_explain", "artins_terms", "mama_terms", "mama_three", "nekit_talk", "nekit_deal", "nekit_threat", "allies", "battle_plan", "lira_teleport", "war_council", "artins_hand", "act3_final", "lira_last", "kai_last", "artins_last", "dawn", "ch4_teleport", "teleport_refuse", "arena_arrival", "act4_start", "nekit_first", "nekit_fight", "nekit_shadows", "nekit_memory", "vanya_joins", "demid_joins", "bogdan_turn", "beast_contract", "karina_fire", "artins_jealousy", "artins_rage", "embrace", "duel", "karina_call", "sacrifice_moment", "mama_ultimatum", "final_choice", "ending_ash", "ending_shard", "ending_loop"}

return StoryData
