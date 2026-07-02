package monitor

// Main MQTT broker used for Zigbee2MQTT traffic.
broker: "mqtt://192.168.1.10:1883"

// Optional runtime context values.
// Your app can calculate these dynamically instead of keeping them in config.
context: {
	period: "day" | "night"
}

#Space: "bedroom A" | "kitchen" | "hallway" | "living room"

#DeviceKind:
	"sonoff-contact-v1" |
	"sonoff-motion-v1" |
	"zigbee-light-switch-v1"

#Device: {
	description: string
	space:       #Space
	kind:        #DeviceKind

	// Zigbee2MQTT state topic.
	topic: string

	// Optional command topic for devices that can receive commands.
	commandTopic?: string
}

devices: [ID=string]: #Device & {
	id?: ID
}

devices: {
	bedroom_A_door_contact: {
		description: "Door leading to bedroom A"
		space:       "bedroom A"
		kind:        "sonoff-contact-v1"
		topic:       "zigbee2mqtt/bedroom_A_door_contact"
	}

	kitchen_motion_sensor: {
		description: "Motion sensor in kitchen"
		space:       "kitchen"
		kind:        "sonoff-motion-v1"
		topic:       "zigbee2mqtt/kitchen_motion_sensor"
	}

	kitchen_light_switch: {
		description:  "Kitchen light switch"
		space:        "kitchen"
		kind:         "zigbee-light-switch-v1"
		topic:        "zigbee2mqtt/kitchen_light_switch"
		commandTopic: "zigbee2mqtt/kitchen_light_switch/set"
	}
}

#SenderKind: "mqtt" | "aws-sns"

#Sender: {
	description?: string
	kind:         #SenderKind

	if kind == "mqtt" {
		broker: string
	}

	if kind == "aws-sns" {
		profile: string
		arn:     =~"^arn:aws:sns:"
	}
}

senders: [ID=string]: #Sender & {
	id?: ID
}

senders: {
	mqtt: {
		description: "Default MQTT sender"
		kind:        "mqtt"
		broker:      broker
	}

	home_sns: {
		description: "SNS topic for home alerts"
		kind:        "aws-sns"
		profile:     "raspberry"
		arn:         "arn:aws:sns:eu-west-2:123456789012:home"
	}
}

#Priority: "low" | "normal" | "high"

#Message: {
	description: string

	// Notification-style fields.
	title?:    string
	priority?: #Priority | *"normal"

	// MQTT-style fields.
	recipient?: string
	output?:    bool | string | number
}

#Action: {
	sender:  string
	message: #Message
}

#Rule: {
	description?: string

	// Lua expression evaluated by the runtime.
	//
	// Suggested runtime context:
	//   devices.bedroom_A_door_contact.contact
	//   devices.kitchen_motion_sensor.occupancy
	//   period
	when: string

	then: [...#Action]
}

rules: [ID=string]: #Rule & {
	id?: ID
}

rules: {
	bedroom_door_open: {
		description: "Send a home notification when the bedroom A door opens"

		when: "devices.bedroom_A_door_contact.contact == true"

		then: [
			{
				sender: "home_sns"
				message: {
					title:       "Bedroom door open"
					description: "The door in bedroom A is open"
					priority:    "normal"
				}
			},
		]
	}

	kitchen_motion_at_night: {
		description: "Turn on the kitchen light when motion is detected at night"

		when: "devices.kitchen_motion_sensor.occupancy == true and period == \"night\""

		then: [
			{
				sender: "mqtt"
				message: {
					description: "Turn on the kitchen light"
					recipient:   "kitchen_light_switch"
					output:      true
				}
			},
		]
	}

	kitchen_motion_notify_at_night: {
		description: "Notify when motion is detected in the kitchen at night"

		when: "devices.kitchen_motion_sensor.occupancy == true and period == \"night\""

		then: [
			{
				sender: "home_sns"
				message: {
					title:       "Kitchen motion"
					description: "Someone is in the kitchen"
					priority:    "high"
				}
			},
		]
	}
}
