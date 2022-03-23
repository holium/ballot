import { BaseAPI } from "./base";
// import { ParticipantType } from "../types/participants";
export class VotesApi extends BaseAPI {
  /**
   *
   * @param boothKey - booth key value
   * @param proposalKey - proposal key value
   * @param choice - a choice object within the choices array that this ship has chosen
   * @returns 200 on success w/ a string message in the body
   */
  castVote = async (boothKey: string, proposalKey: string, choice: any) => {
    const actionUrl = `${this.baseUrl}/ballot/api/booths`;
    try {
      const response = await fetch(actionUrl, {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          action: "cast-vote",
          resource: "booth",
          context: {
            "booth-key": boothKey,
            "proposal-key": proposalKey,
          },
          data: {
            choice,
          },
        }),
      });
      return [await response.json(), null];
    } catch (error) {
      return [null, this.handleErrors(error)];
    }
  };
  /**
   *
   * @returns - array of booth objects
   */
  async initialVotes(boothKey: string, proposalKey: string): Promise<any> {
    const scryUrl = `${this.baseUrl}/~/scry/ballot/booths/${boothKey}/proposals/${proposalKey}/votes`;
    try {
      const response = await fetch(scryUrl, {
        method: "GET",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
      });
      return [await response.json(), null];
    } catch (error) {
      return [this.handleErrors(error), null];
    }
  }
}

export default new VotesApi();
