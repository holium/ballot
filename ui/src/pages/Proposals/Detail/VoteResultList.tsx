import React, { FC } from "react";
import styled from "styled-components";
import { Flex, Ship, Sigil, Text, ThemeType } from "@holium/design-system";
import { VoteModelType } from "../../../logic/stores/proposals";
import { useMst } from "../../../logic/stores/root";
import { DelegateModelType } from "../../../logic/stores/delegates/delegate";

interface IProps {
  votes: Map<string, VoteModelType>;
}

type StyleTableProps = {
  theme: ThemeType;
};

const StyledTable = styled.table<StyleTableProps>`
  -webkit-font-smoothing: antialiased;
  width: 100%;
  border-collapse: collapse;

  th {
    box-sizing: border-box;
    margin: 0px;
    min-width: 0px;
    text-transform: uppercase;
    font-size: 12px;
    font-weight: 600;
    color: ${(props: StyleTableProps) => props.theme.colors.text.tertiary};
    letter-spacing: 0.05em;
    text-align: left;
    padding-bottom: 10px;
    width: 30%;
  }

  td {
    box-sizing: border-box;
    margin: 0px;
    min-width: 0px;
    padding-bottom: 10px;
    font-size: 16px;
    p {
      font-size: 16px;
    }
  }
`;

export const VoteResultList: FC<IProps> = (props: IProps) => {
  const voteArray = Array.from(props.votes.values());
  const { metadata } = useMst();

  return (
    <StyledTable>
      <thead>
        <tr>
          <th style={{ width: "250px" }}>Ship</th>
          <th style={{ width: "auto" }}>Option</th>
          <th style={{ width: "60px" }}>Votes</th>
        </tr>
      </thead>

      {voteArray.map((vote: VoteModelType) => {
        const participantMetadata: any = metadata.contactsMap.get(
          vote.voter
        ) || {
          color: "#000",
        };
        const delegateArray = Array.from(vote.delegators.values());
        return (
          <tbody key={`voter-${vote.voter}`}>
            <tr>
              <td>
                <Ship
                  patp={vote.voter}
                  avatar={participantMetadata.avatar}
                  nickname={null}
                  color={participantMetadata.color || "#000000"}
                  size="small"
                  clickable={false}
                />
              </td>
              <td style={{ width: "auto" }}>{vote.choice.label}</td>
              <td style={{ width: "100px" }}>{vote.delegators.size + 1}</td>
            </tr>
            {delegateArray.map((delegate: DelegateModelType, index: number) => {
              return (
                <tr key={`delegator-${delegate.sig!.voter}-${index}`}>
                  <td colSpan={3}>
                    <Flex flexDirection="row" alignItems="center">
                      <Text
                        style={{ opacity: 0.95 }}
                        ml={8}
                        variant={"patp"}
                        fontWeight="500"
                      >
                        {delegate.sig!.voter}
                      </Text>
                      <Text style={{ opacity: 0.5 }} ml={8} variant={"body"}>
                        (delegator)
                      </Text>
                    </Flex>
                  </td>
                </tr>
              );
            })}
          </tbody>
        );
      })}
    </StyledTable>
  );
};
