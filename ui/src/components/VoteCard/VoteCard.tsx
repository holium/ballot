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
  Notification,
  Tooltip,
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
  delegate?: any;
  title: string;
  blurred?: boolean;
  loading?: boolean;
  timeLeft?: string;
  castingLoading?: boolean;
  strategy: string;
  choices: ChoiceModelType[];
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
    delegate,
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
    middleSection = choices?.map((choice: ChoiceModelType) => (
      <VoteCardButton
        variant="custom"
        disabled={disabled || votingPower === 0}
        chosenOption={chosenVote?.chosenVote?.label === choice.label}
        additionalVariant="option"
        key={choice.label}
        type="button"
        onClick={() =>
          setChosenVote({
            chosenVote: {
              label: choice.label,
              action: choice.action!,
            },
            proposalId: proposalId,
          })
        }
      >
        {choice.label}{" "}
        {choice.action && (
          <Tooltip
            style={{ position: "absolute", right: 6 }}
            content={
              <Card>
                <ActionDataTable action={choice.action!} data={choice.data} />
              </Card>
            }
            placement="bottom-left"
            delay={0.5}
          >
            <Icons.TerminalLine opacity={0.5} color="text.primary" />
          </Tooltip>
        )}
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
        {delegate && (
          <Flex
            display="inline-flex"
            alignItems="center"
            justifyContent="center"
            textAlign="center"
            flexDirection="column"
            mt={1}
            pl={2}
            pr={2}
          >
            <Notification hasBorder customColor="#EF9134">
              <Flex
                width="100%"
                flex={1}
                flexDirection="column"
                alignItems="center"
              >
                <Text fontSize={2} fontWeight={400}>
                  You've delegated to
                </Text>
                <Text fontSize={2} fontWeight={600}>
                  {delegate.delegate}
                </Text>
              </Flex>
            </Notification>
          </Flex>
        )}
        <Text mt={3} mb={3} variant="body">
          {title}
        </Text>

        <Grid position="relative" gridTemplateRows="auto" gridRowGap={1}>
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

export const ActionDataTable = (props: any) => {
  const actionConfig = Object.fromEntries(props.data);
  const keys = Object.keys(actionConfig);
  const values = Object.values<any>(actionConfig);
  return (
    <table>
      <tbody>
        <tr>
          <td style={{ opacity: 0.7 }} colSpan={1}>
            action:
          </td>
          <td colSpan={2}>{props.action}</td>
        </tr>

        {keys.map((key: string, index: number) => (
          <tr key={key}>
            <td style={{ opacity: 0.7 }} colSpan={1}>
              {key}:
            </td>
            <td colSpan={2}>{values[index].toString()}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
};
