export interface Initialized {
  kind: "initialized";
}

export interface Loading {
  kind: "loading";
  url: string;
}

export interface Ready {
  kind: "ready";
  body: any;
}

export interface Failed {
  kind: "failed";
  message: string;
}
