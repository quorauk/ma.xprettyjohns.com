---
title: "Typescript Grpc Service"
date: 2019-11-10T00:28:18Z
tags: 
    - typescript
    - grpc
    - microservices
---

This weekend I thought I would play with typescript and GRPC a little. It seems docs on getting this up and running is a bit thin on the ground, so that makes it perfect candidate for a little blog post.

You can find example code [here](https://github.com/quorauk/grpc-typescript-example)

To get started we need to create project, do so with the following commands

{{< highlight bash "linenos=table" >}}
mkdir grpc-project
yarn init
mkdir -p src/proto
yarn add typescript ts-node grpc grpc-tools ts-protoc-gen @grpc/proto-loader
{{</ highlight >}}

now we will want to create a protoc service so we can do some tasty code generation, here is an example proto file to get started

{{< highlight proto "linenos=table" >}}
// service.proto

syntax = "proto3";

message Message {
    string message = 1;
}

service Greeter {
    rpc greet (Message) returns (Message) {}
}
{{</ highlight >}}

sweet, now we want to get a little typescript going, to do this we want a tsconfig.json file so the compiler knows how to compile your code.

{{< highlight json "linenos=table" >}}
// tsconfig.json
{
    "compilerOptions": {
        "target": "es6",
        "module": "commonjs",
        "noImplicitAny": true,
        "removeComments": true,
        "preserveConstEnums": true,
        "sourceMap": true
    }
}
{{</ highlight >}}

then we want to generate the code that will help us use this proto file in our typescript code. Add the following to package.json

{{< highlight json "linenos=table" >}}
{
...
    "scripts": {
        "proto": "grpc_tools_node_protoc --plugin=protoc-gen-grpc=./node_modules/.bin/grpc_tools_node_protoc_plugin --plugin=protoc-gen-ts=./node_modules/.bin/protoc-gen-ts -I . ./service.proto --js_out='import_style=commonjs,binary:src/proto' --grpc_out=src/proto --ts_out='service=grpc-node:src/proto'"
    }
...
}
{{</ highlight >}}

now you can run the code generation using

{{< highlight bash "linenos=table" >}}
yarn proto
{{</ highlight >}}

and you should see the code appear in src/proto/

now we want to write our server code, here is an example to get you started

{{< highlight typescript "linenos=table" >}}
// src/index.ts
import { Message } from "./proto/service_pb";
import * as grpc from "grpc";
import { GreeterService } from "./proto/service_grpc_pb";

function greet(
  call: grpc.ServerUnaryCall<Message>,
  callback: grpc.requestCallback<Message>
) {
  const resp = new Message();
  resp.setMessage(`hello ${call.request.getMessage()}`);
  callback(null, resp);
}

function main() {
  const server = new grpc.Server();
  server.addService(GreeterService, {
    greet: greet
  });
  const bindto = `0.0.0.0:50051`;
  server.bind(bindto, grpc.ServerCredentials.createInsecure());
  console.log(`STARTING SERVER ON ${bindto}`);
  server.start();
}

main();
{{</ highlight >}}

we can run this with

{{< highlight bash "linenos=table" >}}
yarn run ts-node src/index.ts
{{</ highlight >}}

and to create a basic client

{{< highlight typescript "linenos=table" >}}
// src/client.ts
import { Message } from "./proto/service_pb";
import * as grpc from "grpc";
import { GreeterService } from "./proto/service_grpc_pb";

function greet(
  call: grpc.ServerUnaryCall<Message>,
  callback: grpc.requestCallback<Message>
) {
  const resp = new Message();
  resp.setMessage(`hello ${call.request.getMessage()}`);
  callback(null, resp);
}

function main() {
  const server = new grpc.Server();
  server.addService(GreeterService, {
    greet: greet
  });
  const bindto = `0.0.0.0:50051`;
  server.bind(bindto, grpc.ServerCredentials.createInsecure());
  console.log(`STARTING SERVER ON ${bindto}`);
  server.start();
}

main();
{{</ highlight >}}


similarly run this in a separate terminal with 

{{< highlight bash "linenos=table" >}}
yarn run ts-node src/client.ts
yarn run v1.19.1
$ /home/max/workspace/quora/grpc-typescript-example/node_modules/.bin/ts-node src/client.ts
hello Max
Done in 1.03s.
{{</ highlight >}}

And there we have it, a basic grpc endpoint in typescript!