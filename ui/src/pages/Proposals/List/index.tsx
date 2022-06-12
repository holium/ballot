import React, { FC, useState } from "react";
import { useNavigate, useParams } from "react-router";
import { observer } from "mobx-react-lite";

import {
  ListHeader,
  OptionType,
  VirtualizedList,
  Text,
  Flex,
  Grid2,
  Button,
  Select,
  Label,
  Box,
  IconButton,
  Icons,
} from "@holium/design-system";

import { ProposalType } from "../../../logic/types/proposals";
import { appName } from "../../../app";
import { ProposalCard } from "../../../components/ProposalCard";
import { Participants } from "../../../components/Participants";
import {
  createPath,
  getKeyFromUrl,
  getNameFromUrl,
} from "../../../logic/utils/path";
import { useMst } from "../../../logic/stores/root";
import { ProposalModelType } from "../../../logic/stores/proposals";
import { getProposalFilters } from "../../../logic/stores/proposals/utils";
import { getBoothName } from "../../../logic/utils/metadata";
import { toJS } from "mobx";
import { useMobile } from "../../../logic/utils/useMobile";

export const ProposalList: FC = observer(() => {
  const [selectedOption, setSelectedOption] = useState("All");
  const navigate = useNavigate();
  const urlParams = useParams();
  const isMobile = useMobile();
  const { store, metadata } = useMst();
  const [page, setPage] = useState(0);

  const currentBoothName = getNameFromUrl(urlParams);
  const currentBoothKey = getKeyFromUrl(urlParams);
  let leftPane;

  // leftPane = useMemo(() => {
  const booth = store.booth;
  let proposalsList: any[] = booth?.listProposals!;

  const hasCreatePermission = booth?.hasCreatePermission;
  const isOwner = booth?.isOwner;
  const statusCounts = getProposalFilters(proposalsList);
  if (selectedOption === "All") {
    proposalsList = proposalsList;
  } else {
    proposalsList = proposalsList.filter(
      (proposal: ProposalType) => proposal.status === selectedOption
    );
  }

  const pages =
    proposalsList.length % 10 === 0
      ? Math.floor(proposalsList.length / 10) - 1
      : Math.floor(proposalsList.length / 10);
  const startIndex = page * 10;
  const endIndex = startIndex + 10;

  const pagedList = proposalsList.slice(startIndex, endIndex);
  // return (
  leftPane = (
    <Flex
      mb="8px"
      style={{ height: "inherit" }}
      flex={1}
      flexDirection="column"
    >
      <ListHeader
        title="Proposals"
        subtitle={{ text: getBoothName(booth!) }}
        options={[
          {
            label: "All",
            value: "All",
          },
          {
            label: "Upcoming",
            value: "Upcoming",
            disabled: statusCounts["Upcoming"] ? false : true,
          },
          {
            label: "Active",
            value: "Active",
            disabled: statusCounts["Active"] ? false : true,
          },
          {
            label: "Ended",
            value: "Ended",
            disabled: statusCounts["Ended"] ? false : true,
          },
        ]}
        selectedOption={selectedOption}
        rightContent={
          // @ts-ignore
          hasCreatePermission && (
            <Button
              pt="6px"
              pb="6px"
              variant="transparent"
              onClick={() => {
                navigate(
                  `/apps/${appName}/booth/${currentBoothKey}/proposals/create-new`
                );
              }}
            >
              Create proposal
            </Button>
          )
        }
        rightOptions={
          // TODO make responsive
          <Flex style={{ width: 200 }} justifyContent="flex-end" itemsCenter>
            <Select
              small
              leftInteractive={true}
              leftIcon={
                <Label
                  style={{ opacity: 0.7, fontWeight: "normal", width: 50 }}
                >
                  Sort by
                </Label>
              }
              selectionOption={booth!.sortBy}
              options={[
                {
                  label: "Recent",
                  value: "recent",
                },
                {
                  label: "Next ending",
                  value: "ending",
                },
                {
                  label: "Next starting",
                  value: "starting",
                },
              ]}
              onSelected={(option: {
                value: "recent" | "ending" | "starting";
              }) => {
                booth?.setSortBy(option.value);
              }}
            />
          </Flex>
        }
        onSelected={(option: OptionType) => {
          setSelectedOption(option.label);
        }}
      />
      {pagedList.length ? (
        <VirtualizedList
          id={`list-${currentBoothKey}-${new Date().getMilliseconds()}`}
          style={{
            marginTop: 8,
            height: "calc(100% - 12px)",
          }}
          itemHeight={112}
          numItems={pagedList.length}
          renderItem={({
            key,
            index,
            style,
          }: {
            key: number;
            index: number;
            style: any;
          }) => {
            const proposal: ProposalModelType = pagedList[index];
            const authorMetadata: any = metadata.contactsMap.get(
              proposal.owner
            ) || {
              color: "#000",
            };
            return (
              <ProposalCard
                key={key}
                proposal={proposal}
                onClick={(proposal: ProposalModelType) => {
                  let newPath = createPath(
                    booth!.key,
                    "proposals",
                    proposal.key
                  );
                  navigate(newPath);
                }}
                authorMetadata={authorMetadata}
                status={proposal.status}
                entity={booth!.type}
                contextMenu={[
                  // {
                  //   label: "Copy link",
                  //   onClick: (event: React.MouseEvent<HTMLElement>) => {
                  //     event.stopPropagation();
                  //     console.log("add copy and pasted link");
                  //   },
                  // },
                  // TODO do a check if the proposal is owned by the pariticpant
                  {
                    label: "Edit",
                    disabled:
                      proposal.status === "Active" ||
                      proposal.status === "Ended" ||
                      !hasCreatePermission,
                    // TODO add disabled text
                    onClick: (event: React.MouseEvent<HTMLElement>) => {
                      event.stopPropagation();
                      const proposalStore = booth?.proposalStore!;
                      proposalStore.setActive(proposal!);
                      let newPath = createPath(
                        booth!.key,
                        "proposals/editor",
                        proposal.key
                      );
                      navigate(newPath);
                    },
                  },
                  {
                    label: "Delete",
                    intent: "alert",
                    disabled:
                      !hasCreatePermission ||
                      proposal.status === "Active" ||
                      proposal.status === "Ended",
                    section: 2,
                    onClick: (event: React.MouseEvent<HTMLElement>) => {
                      event.stopPropagation();
                      const proposalStore = booth?.proposalStore!;
                      proposalStore.remove(proposal.key);
                    },
                  },
                ]}
              />
            );
          }}
        />
      ) : (
        <Text
          variant="body"
          style={{
            opacity: 0.6,
            height: 110,
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
          }}
        >
          No proposals
        </Text>
      )}
      {pages > 0 && (
        <Flex
          mt={2}
          mb={2}
          position="relative"
          justifyContent="space-between"
          alignItems="center"
          justifySelf="flex-end"
        >
          <Box top="4px" left="8px" right="unset" bottom="unset">
            <IconButton
              disabled={page <= 0}
              onClick={() => page > 0 && setPage(page - 1)}
            >
              <Icons.AngleLeft />
            </IconButton>
          </Box>
          <Box>
            <Text opacity={0.7} variant="hint">
              {" "}
              {`${page + 1} of ${pages + 1}`}
            </Text>
          </Box>
          <Box top="4px" left="unset" right="8px" bottom="unset">
            <IconButton
              disabled={page >= pages}
              onClick={() => page < pages && setPage(page + 1)}
            >
              <Icons.AngleRight />
            </IconButton>
          </Box>
        </Flex>
      )}
    </Flex>
  );
  // }, [currentBooth, booth?.proposals, selectedOption]);

  const participants = booth ? booth.listParticipants : [];
  const participantLoading = booth ? booth.participantStore.isLoading : false;
  return (
    <Grid2.Box offset={40} fluid scroll>
      <Grid2.Box {...(isMobile && { p: 0 })}>
        <Grid2.Column
          {...(isMobile && { noGutter: true })}
          mt="16px"
          lg={12}
          xl={12}
        >
          <Grid2.Row justify="center">
            <Grid2.Column xs={4} sm={5} md={5} lg={9} xl={9}>
              {leftPane}
            </Grid2.Column>
            <Grid2.Column xs={4} sm={3} md={3} lg={3}>
              <Participants
                loading={participantLoading}
                participants={participants}
                onAdd={(patp: string) => {
                  booth!.participantStore.add(patp);
                }}
                onRemove={(patp: string) => {
                  booth!.participantStore.remove(patp);
                }}
              />
            </Grid2.Column>
          </Grid2.Row>
        </Grid2.Column>
      </Grid2.Box>
    </Grid2.Box>
  );
});
// return (
//   <CenteredPane style={{ height: "100%" }} width={1216} bordered={false}>
//     <Grid2.Box>
//       <Grid2.Row>
//         <Grid2.Column>{leftPane}</Grid2.Column>
//         <Grid2.Column>
//           <Flex style={{ width: 300, height: "fit-content" }}>
//             <Participants
//               loading={participantLoading}
//               participants={participants}
//               onAdd={(patp: string) => {
//                 store.booth!.participantStore.add(patp);
//               }}
//               onRemove={(patp: string) => {
//                 store.booth!.participantStore.remove(patp);
//               }}
//             />
//           </Flex>
//         </Grid2.Column>
//       </Grid2.Row>
//     </Grid2.Box>
//     {/* <Grid
// mt={16}
// flex={1}
// style={{ height: "inherit" }}
// gridTemplateColumns="2fr 300px"
// gridColumnGap={16}
//     >
//       {leftPane}
//       <Flex style={{ width: 300, height: "fit-content" }}>
//         <Participants
//           loading={participantLoading}
//           participants={participants}
//           onAdd={(patp: string) => {
//             store.booth!.participantStore.add(patp);
//           }}
//           onRemove={(patp: string) => {
//             store.booth!.participantStore.remove(patp);
//           }}
//         />
//       </Flex>
//     </Grid> */}
//   </CenteredPane>
// );
