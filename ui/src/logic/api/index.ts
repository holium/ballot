import Urbit from "@urbit/http-api";
const api = new Urbit("", "", (window as any).desk);
api.ship = window.ship;
api.verbose = true;
// @ts-ignore TODO window typings
window.api = api;

export default api;
// export default {}

// // TODO build generic api
// const example = {
//   id: 1,
//   action: "poke",
//   ship: "zod",
//   app: "hood",
//   mark: "helm-hi",
//   json: JSON.stringify({
//     action: "save-proposal", // save-proposal
//     booth: "~zod", // booth name
//     name: "Vote on me bitch", // proposal name
//     content: {
//       title: "Vote on me bitch",
//       body: "Hello world",
//       strategy: "single-choice",
//       status: "draft",
//       published: false,
//       hideIndividualVote: false,
//       choices: [
//         {
//           label: "Yes",
//           description: "",
//         },
//         {
//           label: "No",
//           description: "",
//         },
//       ],
//       start: new Date(), // epoch (milliseconds since 1970),
//       end: new Date(), // epoch (milliseconds since 1970),
//       createdBy: "~zod", // ship (@p)
//       createdAt: new Date(), // epoch (milliseconds since 1970),
//     },
//   }),
// };
