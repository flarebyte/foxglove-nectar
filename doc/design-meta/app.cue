package flyb

source: "foxglove-nectar-design-meta"
name:   "foxglove-nectar"
modules: ["core"]

reports: [{
	title:       "Foxglove Nectar Design"
	filepath:    "../design/foxglove-nectar.md"
	description: "Design source for a local Go CLI that monitors Zigbee and MQTT devices, normalizes their payloads, and triggers local actions or alerts."
	sections: [{
		title:       "01 Overview"
		description: "Product intent and runtime workflow."
		sections: [{
			title:       "01 Intent"
			description: "The operating goal for the CLI."
			notes: ["foxglove.intent", "foxglove.scope"]
		}, {
			title:       "02 Runtime Flow"
			description: "The expected monitor loop from broker connection to dispatched action."
			notes: ["foxglove.flow.01-connect", "foxglove.flow.02-observe", "foxglove.flow.03-evaluate", "foxglove.flow.04-dispatch"]
		}, {
			title:       "03 Flow Graph"
			description: "Graph view of the runtime flow."
			arguments: [
				"graph-subject-label=runtime-flow",
				"graph-edge-label=then",
				"graph-start-node=foxglove.flow.01-connect",
				"graph-renderer=markdown-text",
			]
		}]
	}, {
		title:       "02 Source Inputs"
		description: "Durable specs and examples used by the design."
		sections: [{
			title:       "01 Prerequisites"
			description: "Host, network, broker, Zigbee, and deployment requirements."
			notes: ["foxglove.prerequisites"]
		}, {
			title:       "02 Device Catalog"
			description: "Known Zigbee and MQTT device families, primary fields, and availability conventions."
			notes: ["foxglove.devices"]
		}, {
			title:       "03 Monitor Config"
			description: "Declarative monitor-domain sketch for devices, senders, messages, and rules."
			notes: ["foxglove.monitor.config"]
		}]
	}, {
		title:       "03 MQTT Payload Examples"
		description: "Representative MQTT JSON payloads that the Go CLI should parse and normalize."
		sections: [{
			title:       "01 Zigbee2MQTT Sensors"
			description: "Sonoff contact and motion sensor payloads."
			notes: ["foxglove.payload.sonoff-door-contact", "foxglove.payload.sonoff-motion-sensor"]
		}, {
			title:       "02 Shelly Switches and Power"
			description: "Shelly switch, plug, and energy monitor payloads."
			notes: [
				"foxglove.payload.shelly-1pm-gen4",
				"foxglove.payload.shelly-plug-s-gen3",
				"foxglove.payload.shelly-pro-4pm",
				"foxglove.payload.shelly-em",
			]
		}, {
			title:       "03 Shelly Environmental Sensors"
			description: "Shelly flood and temperature/humidity payloads."
			notes: ["foxglove.payload.shelly-flood-gen4", "foxglove.payload.shelly-ht-gen3"]
		}]
	}, {
		title:       "04 Design Notes"
		description: "Implementation notes for turning the specs into a Go CLI."
		sections: [{
			title:       "01 Normalization"
			description: "How payloads should become a stable internal event stream."
			notes: ["foxglove.normalization"]
		}, {
			title:       "02 Reliability"
			description: "Broker, availability, and rule execution expectations."
			notes: ["foxglove.reliability"]
		}, {
			title:       "03 Open Questions"
			description: "Decisions that should be settled before implementation hardens."
			notes: ["foxglove.open-questions"]
		}]
	}]
}]

notes: [
	{
		name:  "foxglove.intent"
		title: "Local Device Monitor"
		markdown: """
			Foxglove Nectar is a Go CLI for monitoring local MQTT traffic from Zigbee2MQTT and native MQTT devices.
			
			The CLI should connect to a configured broker, subscribe to device topics, decode known JSON payloads, evaluate rules, and dispatch local MQTT commands or alert messages without requiring a cloud control plane.
			"""
		labels: ["overview", "product"]
	},
	{
		name:  "foxglove.scope"
		title: "Initial Scope"
		markdown: """
			The first design scope covers MQTT connectivity, Zigbee2MQTT sensor payloads, Shelly MQTT payloads, availability tracking, rule evaluation, and sender abstractions for MQTT and alert-style outputs.
			
			Configuration should stay explicit and file-backed so a Raspberry Pi or similar home server can run the CLI unattended.
			"""
		labels: ["overview", "scope"]
	},
	{
		name:     "foxglove.flow.01-connect"
		title:    "Connect to Broker"
		markdown: "Load configuration, connect to the MQTT broker, and establish subscriptions for device state and availability topics."
		labels: ["runtime-flow"]
	},
	{
		name:     "foxglove.flow.02-observe"
		title:    "Observe Device Messages"
		markdown: "Decode payloads from Zigbee2MQTT and Shelly topics into typed observations with raw topic, timestamp, device id, and normalized fields."
		labels: ["runtime-flow"]
	},
	{
		name:     "foxglove.flow.03-evaluate"
		title:    "Evaluate Rules"
		markdown: "Update device state, evaluate rule expressions against the latest state and context, and create action intents when conditions match."
		labels: ["runtime-flow"]
	},
	{
		name:     "foxglove.flow.04-dispatch"
		title:    "Dispatch Actions"
		markdown: "Send MQTT command messages or alert messages through configured senders, with logging that links each action back to its triggering rule."
		labels: ["runtime-flow"]
	},
	{
		name:     "foxglove.prerequisites"
		title:    "Prerequisites"
		filepath: "examples/pre-requisites.csv"
		arguments: ["format-csv=table"]
		labels: ["csv", "requirements"]
	},
	{
		name:     "foxglove.devices"
		title:    "Device Catalog"
		filepath: "examples/devices.csv"
		arguments: ["format-csv=table"]
		labels: ["csv", "device"]
	},
	{
		name:     "foxglove.monitor.config"
		title:    "Monitor Config Sketch"
		filepath: "examples/monitor.cue"
		labels: ["config", "cue"]
	},
	{
		name:     "foxglove.payload.shelly-1pm-gen4"
		title:    "Shelly 1PM Gen4 Payload"
		filepath: "examples/device/shelly-1pm-gen4.json"
		labels: ["device", "json", "mqtt", "shelly"]
	},
	{
		name:     "foxglove.payload.shelly-em"
		title:    "Shelly EM Payload"
		filepath: "examples/device/shelly-em.json"
		labels: ["device", "json", "mqtt", "shelly"]
	},
	{
		name:     "foxglove.payload.shelly-flood-gen4"
		title:    "Shelly Flood Gen4 Payload"
		filepath: "examples/device/shelly-flood-gen4.json"
		labels: ["device", "json", "mqtt", "shelly"]
	},
	{
		name:     "foxglove.payload.shelly-ht-gen3"
		title:    "Shelly H&T Gen3 Payload"
		filepath: "examples/device/shelly-ht-gen3.json"
		labels: ["device", "json", "mqtt", "shelly"]
	},
	{
		name:     "foxglove.payload.shelly-plug-s-gen3"
		title:    "Shelly Plug S Gen3 Payload"
		filepath: "examples/device/shelly-plug-s-gen3.json"
		labels: ["device", "json", "mqtt", "shelly"]
	},
	{
		name:     "foxglove.payload.shelly-pro-4pm"
		title:    "Shelly Pro 4PM Payload"
		filepath: "examples/device/shelly-pro-4pm.json"
		labels: ["device", "json", "mqtt", "shelly"]
	},
	{
		name:     "foxglove.payload.sonoff-door-contact"
		title:    "Sonoff Door Contact Payload"
		filepath: "examples/device/sonoff-door-contact-sensor.json"
		labels: ["device", "json", "mqtt", "sonoff", "zigbee"]
	},
	{
		name:     "foxglove.payload.sonoff-motion-sensor"
		title:    "Sonoff Motion Sensor Payload"
		filepath: "examples/device/sonoff-motion-sensor.json"
		labels: ["device", "json", "mqtt", "sonoff", "zigbee"]
	},
	{
		name:  "foxglove.normalization"
		title: "Normalization Contract"
		markdown: """
			Normalize each incoming MQTT payload into a common observation shape before rules inspect it.
			
			The normalized event should retain the original topic and payload, expose a stable device id, classify the device family, and map known fields such as contact, occupancy, output, power, water_leak, temperature, humidity, battery, and linkquality into predictable names.
			"""
		labels: ["implementation", "normalization"]
	},
	{
		name:  "foxglove.reliability"
		title: "Reliability Expectations"
		markdown: """
			The CLI should treat MQTT connection state and device availability as first-class runtime state.
			
			Rules should avoid firing on stale observations, availability transitions should be logged, and dispatch failures should be visible without stopping unrelated device monitoring.
			"""
		labels: ["implementation", "reliability"]
	},
	{
		name:  "foxglove.open-questions"
		title: "Open Questions"
		markdown: """
			1. Which rule expression engine should the Go implementation embed?
			2. Should action dispatch be at-most-once, retrying, or queued durably?
			3. Should the first release support only JSON payloads, or also plain string and numeric MQTT payloads?
			4. Should device schemas be hard-coded in Go, generated from config, or loaded dynamically from design/config files?
			"""
		labels: ["open-question"]
	},
]

relationships: [
	{
		from:  "foxglove.flow.01-connect"
		to:    "foxglove.flow.02-observe"
		label: "then"
		labels: ["then"]
	},
	{
		from:  "foxglove.flow.02-observe"
		to:    "foxglove.flow.03-evaluate"
		label: "then"
		labels: ["then"]
	},
	{
		from:  "foxglove.flow.03-evaluate"
		to:    "foxglove.flow.04-dispatch"
		label: "then"
		labels: ["then"]
	},
	{
		from:  "foxglove.devices"
		to:    "foxglove.normalization"
		label: "informs"
		labels: ["informs"]
	},
	{
		from:  "foxglove.monitor.config"
		to:    "foxglove.reliability"
		label: "informs"
		labels: ["informs"]
	},
]

argumentRegistry: {
	version: "1"
	arguments: [
		{
			name:      "graph-subject-label"
			valueType: "string"
			scopes: ["h3-section"]
		},
		{
			name:      "graph-edge-label"
			valueType: "string"
			scopes: ["h3-section"]
		},
		{
			name:      "graph-start-node"
			valueType: "string"
			scopes: ["h3-section"]
		},
		{
			name:      "graph-renderer"
			valueType: "enum"
			scopes: ["h3-section", "note"]
			allowedValues: ["markdown-text", "mermaid"]
			defaultValue: "markdown-text"
		},
		{
			name:      "format-csv"
			valueType: "enum"
			scopes: ["note"]
			allowedValues: ["raw", "table"]
			defaultValue: "raw"
		},
	]
}
