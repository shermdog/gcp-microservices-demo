/*
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';


if(process.env.DISABLE_PROFILER) {
  console.log("Profiler disabled.")
}
else {
  console.log("Profiler enabled.")
  require('@google-cloud/profiler').start({
    serviceContext: {
      service: 'paymentservice',
      version: '1.0.0'
    }
  });
}


if(process.env.ENABLE_TRACING == "1") {
  console.log("Tracing enabled.")
  const { OTLPTraceExporter } = require("@opentelemetry/exporter-trace-otlp-grpc");
  const { diag, DiagConsoleLogger, DiagLogLevel } = require('@opentelemetry/api');
  const opentelemetry = require("@opentelemetry/sdk-node");
  const { getNodeAutoInstrumentations } = require("@opentelemetry/auto-instrumentations-node");
  const { envDetector, processDetector } = require("@opentelemetry/resources");

  // debug
  // diag.setLogger(new DiagConsoleLogger(), DiagLogLevel.DEBUG);
  
  const collectorUrl = process.env.COLLECTOR_SERVICE_ADDR

  const sdk = new opentelemetry.NodeSDK({
    traceExporter: new OTLPTraceExporter({url: collectorUrl}),
    instrumentations: [getNodeAutoInstrumentations()],
    resourceDetectors: [envDetector, processDetector],
  });

  sdk.start();
}
else {
  console.log("Tracing disabled.")
}


const path = require('path');
const HipsterShopServer = require('./server');

const PORT = process.env['PORT'];
const PROTO_PATH = path.join(__dirname, '/proto/');

const server = new HipsterShopServer(PROTO_PATH, PORT);

server.listen();
