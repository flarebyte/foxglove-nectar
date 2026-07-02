# Foxglove Nectar Design

Design source for a local Go CLI that monitors Zigbee and MQTT devices, normalizes their payloads, and triggers local actions or alerts.

## 01 Overview

Product intent and runtime workflow.

### 01 Intent

The operating goal for the CLI.

#### Local Device Monitor

Foxglove Nectar is a Go CLI for monitoring local MQTT traffic from Zigbee2MQTT and native MQTT devices.

The CLI should connect to a configured broker, subscribe to device topics, decode known JSON payloads, evaluate rules, and dispatch local MQTT commands or alert messages without requiring a cloud control plane.

#### Initial Scope

The first design scope covers MQTT connectivity, Zigbee2MQTT sensor payloads, Shelly MQTT payloads, availability tracking, rule evaluation, and sender abstractions for MQTT and alert-style outputs.

Configuration should stay explicit and file-backed so a Raspberry Pi or similar home server can run the CLI unattended.

### 02 Runtime Flow

The expected monitor loop from broker connection to dispatched action.

#### Connect to Broker

Load configuration, connect to the MQTT broker, and establish subscriptions for device state and availability topics.

#### Observe Device Messages

Decode payloads from Zigbee2MQTT and Shelly topics into typed observations with raw topic, timestamp, device id, and normalized fields.

#### Evaluate Rules

Update device state, evaluate rule expressions against the latest state and context, and create action intents when conditions match.

#### Dispatch Actions

Send MQTT command messages or alert messages through configured senders, with logging that links each action back to its triggering rule.

### 03 Flow Graph

Graph view of the runtime flow.

- <a id="graph-node-foxglove-flow-01-connect"></a> Connect to Broker: Load configuration, connect to the MQTT broker, and establish subscriptions for device state and availability topics.
  - <a id="graph-node-foxglove-flow-02-observe"></a> Observe Device Messages: Decode payloads from Zigbee2MQTT and Shelly topics into typed observations with raw topic, timestamp, device id, and normalized fields.
    - <a id="graph-node-foxglove-flow-03-evaluate"></a> Evaluate Rules: Update device state, evaluate rule expressions against the latest state and context, and create action intents when conditions match.
      - <a id="graph-node-foxglove-flow-04-dispatch"></a> Dispatch Actions: Send MQTT command messages or alert messages through configured senders, with logging that links each action back to its triggering rule.

## 02 Source Inputs

Durable specs and examples used by the design.

### 01 Prerequisites

Host, network, broker, Zigbee, and deployment requirements.

#### Prerequisites

| Raspberry_Pi_install | category | macOS_install | mandatory | notes | requirement |
| --- | --- | --- | --- | --- | --- |
| sudo apt install golang-go | Go runtime | brew install go | YES | Used to compile and run the automation program | Go 1.24+ |
| go get github.com/eclipse/paho.mqtt.golang | MQTT library | go get github.com/eclipse/paho.mqtt.golang | YES | Standard Go MQTT client library | Eclipse Paho Go client |
| sudo apt install mosquitto mosquitto-clients | MQTT broker | brew install mosquitto | YES | Central message bus | Mosquitto |
| sudo apt install mosquitto-clients | MQTT CLI tools | brew install mosquitto | RECOMMENDED | Useful for debugging topics and payloads | mosquitto_pub and mosquitto_sub |
| Plug into USB port | Zigbee coordinator | N/A | ONLY_FOR_ZIGBEE | Examples: Sonoff ZBDongle-E or ZBDongle-P | USB Zigbee dongle |
| docker run ... or npm install zigbee2mqtt | Zigbee bridge | docker run ... or npm install zigbee2mqtt | ONLY_FOR_ZIGBEE | Converts Zigbee messages into MQTT | Zigbee2MQTT |
| Add user to dialout group | Serial permissions | Check /dev/cu.* permissions | ONLY_FOR_ZIGBEE | Needed by Zigbee2MQTT | Access to USB device |
| None | WiFi network | None | YES | Devices and broker must reach each other | Local IP connectivity |
| Optional | DNS or static IP | Optional | RECOMMENDED | Prevents configuration breakage | Stable broker address |
| Optional | TLS certificates | Optional | OPTIONAL | Needed for secure MQTT deployments | CA and client certificates |
| None | Device naming | None | YES | Examples: kitchen_motion or garage_door | Friendly names |
| None | Topic conventions | None | YES | Examples: home/kitchen/motion or site1/pump1/state | Standard topic hierarchy |
| None | Availability topics | None | RECOMMENDED | Examples: device/online or device/availability | Heartbeat convention |
| Included in Go | JSON handling | Included in Go | YES | Use encoding/json | Encoding/decoding support |
| Optional | Configuration management | Optional | RECOMMENDED | Store broker URLs and topic mappings | YAML or JSON config files |
| go get log/slog or zap | Logging | go get log/slog or zap | RECOMMENDED | Useful for debugging automations | Structured logging library |
| sudo apt install docker.io | Container runtime | brew install docker | OPTIONAL | Simplifies deployment | Docker |
| systemd | System service | launchd | RECOMMENDED | Auto-start automation on reboot | Launch agent or systemd |
| None | Monitoring | None | RECOMMENDED | Track MQTT connectivity and device liveness | Health checks |

### 02 Device Catalog

Known Zigbee and MQTT device families, primary fields, and availability conventions.

#### Device Catalog

| device | heartbeat_or_availability | other_fields | primary_field | typical_topic |
| --- | --- | --- | --- | --- |
| Sonoff Zigbee Door Contact | zigbee2mqtt/front_door/availability | battery, voltage, tamper, linkquality | contact | zigbee2mqtt/front_door |
| Sonoff Zigbee Motion Sensor (SNZB-03) | zigbee2mqtt/kitchen_motion/availability | battery, voltage, battery_low, linkquality | occupancy | zigbee2mqtt/kitchen_motion |
| Shelly Pro 4PM | device/online | apower, current, voltage, pf, aenergy, temperature | output | device/status/switch:0..3 |
| Shelly EM | shellies/<id>/online | current, voltage, pf, total, total_returned | power | shellies/<id>/emeter/0..1 |
| Shelly 1PM Gen4 | device/online | apower, current, voltage, pf, aenergy, temperature | output | device/status/switch:0 |
| Shelly Flood Gen4 | home/utility_room/flood/online | temperature, battery, battery_low, tamper | water_leak | home/utility_room/flood/status |
| Shelly Plug S Gen3 | home/coffee_machine/online | apower, current, voltage, pf, aenergy, temperature | output | home/coffee_machine/status/switch:0 |
| Shelly H&T Gen3 | periodic wake-up reports / online status | battery_percent, rssi | temperature_c, humidity_percent | shellyhtg3-<id>/events/rpc |

### 03 Monitor Config

Declarative monitor-domain sketch for devices, senders, messages, and rules.

#### Monitor Config Sketch

```cue
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
```

## 03 MQTT Payload Examples

Representative MQTT JSON payloads that the Go CLI should parse and normalize.

### 01 Zigbee2MQTT Sensors

Sonoff contact and motion sensor payloads.

#### Sonoff Door Contact Payload

```json
{
  "contact": true,
  "battery": 87,
  "voltage": 2955,
  "tamper": false,
  "linkquality": 132
}
```

#### Sonoff Motion Sensor Payload

```json
{
  "occupancy": true,
  "battery": 91,
  "voltage": 3015,
  "linkquality": 142,
  "battery_low": false
}
```

### 02 Shelly Switches and Power

Shelly switch, plug, and energy monitor payloads.

#### Shelly 1PM Gen4 Payload

```json
{
  "id": 0,
  "source": "input",
  "output": true,
  "apower": 847.2,
  "current": 3.68,
  "voltage": 230.1,
  "pf": 0.99,
  "aenergy": {
    "total": 1532847,
    "by_minute": [845, 846, 848]
  },
  "temperature": {
    "tC": 42.7,
    "tF": 108.9
  }
}
```

#### Shelly EM Payload

```json
{
  "power": 1234.5,
  "pf": 0.98,
  "current": 5.36,
  "voltage": 230.2,
  "total": 45231.7,
  "total_returned": 0.0
}
```

#### Shelly Plug S Gen3 Payload

```json
{
  "id": 0,
  "output": true,
  "apower": 1123.4,
  "current": 4.88,
  "voltage": 230.2,
  "pf": 0.99,
  "aenergy": {
    "total": 842156
  },
  "temperature": {
    "tC": 39.8
  }
}
```

#### Shelly Pro 4PM Payload

```json
{
  "id": 0,
  "source": "MQTT",
  "output": true,
  "apower": 142.3,
  "voltage": 230.8,
  "current": 0.617,
  "pf": 0.99,
  "aenergy": {
    "total": 1245876,
    "by_minute": [142, 141, 143]
  },
  "temperature": {
    "tC": 41.2,
    "tF": 106.2
  }
}
```

### 03 Shelly Environmental Sensors

Shelly flood and temperature/humidity payloads.

#### Shelly Flood Gen4 Payload

```json
{
  "water_leak": false,
  "temperature": 21.8,
  "battery": 94,
  "battery_low": false,
  "tamper": false,
  "wifi_status": "connected"
}
```

#### Shelly H&T Gen3 Payload

```json
{
  "src": "shellyhtg3-AABBCCDDEEFF",
  "dst": "mqtt",
  "method": "NotifyStatus",
  "params": {
    "ts": 1719999999.12,
    "temperature:0": {
      "id": 0,
      "tC": 21.8,
      "tF": 71.2
    },
    "humidity:0": {
      "id": 0,
      "rh": 48.5
    },
    "devicepower:0": {
      "id": 0,
      "battery": {
        "V": 5.72,
        "percent": 86
      }
    },
    "wifi": {
      "rssi": -61
    }
  }
}
```

## 04 Design Notes

Implementation notes for turning the specs into a Go CLI.

### 01 Normalization

How payloads should become a stable internal event stream.

#### Normalization Contract

Normalize each incoming MQTT payload into a common observation shape before rules inspect it.

The normalized event should retain the original topic and payload, expose a stable device id, classify the device family, and map known fields such as contact, occupancy, output, power, water_leak, temperature, humidity, battery, and linkquality into predictable names.

### 02 Reliability

Broker, availability, and rule execution expectations.

#### Reliability Expectations

The CLI should treat MQTT connection state and device availability as first-class runtime state.

Rules should avoid firing on stale observations, availability transitions should be logged, and dispatch failures should be visible without stopping unrelated device monitoring.

### 03 Open Questions

Decisions that should be settled before implementation hardens.

#### Open Questions

1. Which rule expression engine should the Go implementation embed?
2. Should action dispatch be at-most-once, retrying, or queued durably?
3. Should the first release support only JSON payloads, or also plain string and numeric MQTT payloads?
4. Should device schemas be hard-coded in Go, generated from config, or loaded dynamically from design/config files?

