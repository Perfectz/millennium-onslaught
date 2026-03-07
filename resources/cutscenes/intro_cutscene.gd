## Intro cutscene data — Alys and Chaz leave town for Piata Academy.
## Returns structured scene data for the CutscenePlayer.
class_name IntroCutscene
extends RefCounted


static func get_scenes() -> Array:
	return [
		{
			"eyebrow": "PROLOGUE",
			"title": "THE MORNING",
			"video": "res://assets/textures/cutscene_scene1.ogv",
			"lines": [
				{"speaker": "", "text": "Morning light spilled across the room. Alys was already geared up -- Chaz was still trying to look like he belonged in armor."},
				{"speaker": "ALYS", "text": "Chaz, we have work to do. Hurry up and get ready."},
				{"speaker": "CHAZ", "text": "O-oh -- right! I'm ready! Mostly!"},
				{"speaker": "ALYS", "text": "This is your first job since you joined the Hunters Guild. You'd better put your heart into it."},
				{"speaker": "CHAZ", "text": "So... I'm not a trainee anymore."},
				{"speaker": "ALYS", "text": "From this day on, you're a full-fledged partner."},
				{"speaker": "ALYS", "text": "Now come on -- let's go."},
			],
		},
		{
			"eyebrow": "PROLOGUE",
			"title": "THE CITY",
			"video": "res://assets/textures/cutscene_scene2.ogv",
			"lines": [
				{"speaker": "", "text": "They stepped out into the heat and noise of town -- vendors calling, guards watching, travelers drifting past like it was any other day."},
				{"speaker": "CHAZ", "text": "Where are we off to this time?"},
				{"speaker": "ALYS", "text": "It's a bit far. We're going to Motavia Academy -- in the town of Piata."},
				{"speaker": "CHAZ", "text": "Wow! The Town of Learning! I wonder what's happened there?"},
				{"speaker": "ALYS", "text": "Who knows? The message said, 'Just come.' We'll get the details once we're there."},
				{"speaker": "CHAZ", "text": "Since we're going to be there anyway... I'd really like to tour the Academy."},
				{"speaker": "ALYS", "text": "And I'd really like you to remember we're being paid to work, not wander."},
				{"speaker": "ALYS", "text": "Principal's office first. Try not to get distracted by the... education."},
			],
		},
		{
			"eyebrow": "PROLOGUE",
			"title": "THE DESERT",
			"video": "res://assets/textures/cutscene_scene3.ogv",
			"lines": [
				{"speaker": "", "text": "The road out of town vanished into sun-bleached sand. Chaz kept glancing toward the distant buildings on the horizon like they were calling his name."},
				{"speaker": "CHAZ", "text": "So the principal called us specifically... That's kind of a big deal, right?"},
				{"speaker": "ALYS", "text": "Don't let it go to your head. Yet."},
				{"speaker": "CHAZ", "text": "Right. No head-going. Just... walking. In sand."},
				{"speaker": "ALYS", "text": "Welcome to Motavia. Keep moving."},
			],
		},
		{
			"eyebrow": "PROLOGUE",
			"title": "THE OATH",
			"video": "res://assets/textures/cutscene_scene4.ogv",
			"lines": [
				{"speaker": "", "text": "AW 2284. Monster attacks have swelled the ranks of those who call themselves Hunters. But as the attacks become ever more frequent and powerful, an elite few begin to wonder what is behind this outbreak... and when -- and how -- it will end.", "voice": "res://assets/audio/voice/s4_narrator_line1.mp3"},
				{"speaker": "ALYS", "text": "Eyes forward, Chaz."},
				{"speaker": "CHAZ", "text": "Yeah... I'm with you."},
			],
		},
	]
