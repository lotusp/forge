#!/usr/bin/env bash
# Detector: ms_listeners
# Counts inbound message-listener annotation occurrences.
# Covers: @MessageListener (Spring + SVC servicebus starter),
# @KafkaListener, @RabbitListener, @JmsListener, @SqsListener,
# @StreamListener, @ServiceBusListener (Azure SDK), @EventHubConsumer,
# bare @Consumer (custom starters that mark handler methods).
#
# Why this exists: v0.5.1 review found SVC projects shipping
# @MessageListener("queue.*") consumers that the old profile prose
# missed entirely. This detector closes the data-drift gap between
# reference/scan-patterns.md and event-consumers.md.
set -euo pipefail
ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "ms_listeners" --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, error: "root not found"}'
  exit 0
fi

PATTERN='@(KafkaListener|RabbitListener|JmsListener|SqsListener|StreamListener|MessageListener|ServiceBusListener|EventHubConsumer|Consumer)\b'
N=$( { grep -rE "$PATTERN" -- "$ROOT" 2>/dev/null || true; } | wc -l | tr -d ' ')
EVIDENCE_CMD="grep -rE '$PATTERN' -- '$ROOT' | wc -l"

jq -n --arg detector "ms_listeners" --arg root "$ROOT" \
      --argjson result "$N" --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root, result: $result, evidence_cmd: $cmd}'
