import React, { useState, useEffect, useMemo } from "react";
import { useParams } from "react-router";
import {
  Card,
  Ship,
  Icons,
  KPI,
  Flex,
  Text,
  Grid,
  Fill,
  Box,
  Spinner,
} from "@holium/design-system";
import { ChoiceType, VoteType } from "../../logic/types/proposals";
import { VoteBreakdownBar } from "../VoteBreakdownBar";
import { VoteCardButton } from "./VoteCard.styles";
import { pluralize } from "../../logic/utils/text";
import {
  ChoiceModelType,
  ResultSummaryType,
  TallyType,
  VoteModelType,
} from "../../logic/stores/proposals";
import { toJS } from "mobx";
import { ContactModelType } from "../../logic/stores/metadata";

export type VoteCardProps = {
  style?: any;
  disabled?: boolean;
  currentUser: {
    patp: string;
    metadata: ContactModelType;
  };
  title: string;
  blurred?: boolean;
  loading?: boolean;
  timeLeft?: string;
  castingLoading?: boolean;
  strategy: string;
  choices: [];
  chosenOption?: ChoiceModelType;
  voteResults?: ResultSummaryType;
  voteSubmitted?: boolean;
  votingPower?: number;
  onClick: (option: string) => any;
  onVote: (chosenVote: VoteType) => any;
};

export const VoteCard: any = (props: VoteCardProps) => {
  const {
    style,
    disabled,
    loading,
    castingLoading,
    currentUser,
    choices,
    strategy,
    timeLeft,
    title,
    blurred,
    // if user exists in list of votes submitted for this proposal, then make voteSubmitted=true, and make chosenOption=the choice object of their vote + proposalId
    chosenOption,
    voteSubmitted,
    voteResults,
    votingPower,
    onClick,
    onVote,
  } = props;
  const ref = React.createRef();
  const urlParams = useParams();
  const proposalId = urlParams.proposalId;

  const [chosenVote, setChosenVote] = useState<VoteType>({
    chosenVote: {
      label: "",
    },
  });

  // Simply resets the vote when you click outside without submitting
  const onClickOutside = () => {
    !voteSubmitted &&
      setChosenVote({
        chosenVote: {
          label: "",
        },
      });
  };

  useEffect(() => {
    const handleClickOutside = (event: any) => {
      // @ts-ignore
      if (ref.current && !ref.current.contains(event.target)) {
        onClickOutside && onClickOutside();
      }
    };
    document.addEventListener("click", handleClickOutside, true);
    return () => {
      document.removeEventListener("click", handleClickOutside, true);
    };
  }, [onClickOutside]);

  let middleSection;
  if (loading) {
    middleSection = (
      <Flex style={{ height: 76 }} justifyCenter itemsCenter>
        <Spinner size={2} />
      </Flex>
    );
  } else if (!chosenOption) {
    middleSection = choices?.map((choice: ChoiceType) => (
      <VoteCardButton
        variant="custom"
        disabled={disabled}
        chosenOption={chosenVote?.chosenVote?.label === choice.label}
        additionalVariant="option"
        key={choice.label}
        type="button"
        onClick={() =>
          setChosenVote({
            chosenVote: {
              label: choice.label,
              action: choice.action,
            },
            proposalId: proposalId,
          })
        }
      >
        {choice.label}
      </VoteCardButton>
    ));
  } else if (chosenOption) {
    middleSection = voteResults && (
      <>
        {voteResults.tallies.map((vote: TallyType) => {
          return (
            <VoteBreakdownBar
              win={vote.label === voteResults.topChoice}
              ourChoice={vote.label === chosenOption.label}
              label={vote.label}
              percentage={vote.percentage}
              width="250px"
              overlay={true}
              key={vote.label}
            />
          );
        })}
        <Flex justifyContent="flex-start" mt={3}>
          <Text opacity={0.6} variant="hint">{`${
            voteResults?.voteCount
          } ${pluralize(
            "vote",
            voteResults?.voteCount! || 0
          )} • ${timeLeft}`}</Text>
        </Flex>
      </>
    );
  }

  return (
    <Card
      ref={ref}
      elevation="lifted"
      style={{
        // position: "sticky",
        borderColor: "transparent",
        padding: "12px",
        ...style,
      }}
    >
      {blurred && (
        <Box
          style={{
            zIndex: 20,
            width: "calc(100% - 24px)",
            padding: "0 12px",
            margin: "90px auto",
            position: "absolute",
          }}
        >
          <Text textAlign="center" variant="h5">
            Please read the proposal text on the left
          </Text>
        </Box>
      )}
      <Fill
        style={{
          filter: blurred ? "blur(8px)" : "none",
          pointerEvents: blurred ? "none" : "initial",
        }}
      >
        <Flex
          justifyContent="space-between"
          alignItems="center"
          style={{
            flex: 1,
            width: "100%",
          }}
          mb={3}
        >
          <Ship
            textOpacity={1}
            patp={currentUser.patp}
            avatar={currentUser.metadata?.avatar}
            nickname={currentUser.metadata?.nickname}
            color={currentUser.metadata?.color || "#000000"}
            size="small"
            clickable={false}
          />
          <Text variant="hint" opacity={0.5}>
            {`${votingPower} ${pluralize("vote", votingPower!)}`}
          </Text>
        </Flex>
        <Text mt={3} mb={3} variant="body">
          {title}
        </Text>
        <Grid gridTemplateRows="auto" gridRowGap={1}>
          {middleSection}
        </Grid>

        <VoteCardButton
          isLoading={castingLoading}
          additionalVariant="submit"
          variant="custom"
          disabled={
            (!chosenOption && chosenVote?.chosenVote?.label === "") ||
            chosenOption !== undefined ||
            loading
          }
          onClick={() => !disabled && onVote(chosenVote)}
        >
          {/* {chosenOption ? <Icons.CheckCircle /> : "Confirm"} */}
          {/* {loading && <Spinner size={0} />} */}
          {!loading && chosenOption && "Voted"}
          {!loading && !chosenOption && "Confirm"}
        </VoteCardButton>

        {/* {chosenOption && (
        <VoteCardButton
          additionalVariant="submit"
          variant="custom"
          disabled={true}
          isLoading={loading}
        >
          <Icons.CheckCircle />
        </VoteCardButton>
      )} */}
      </Fill>
    </Card>
  );
};

VoteCard.defaultProps = {};
