import React, { FC, useState } from "react";
import { toJS } from "mobx";
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
  FormControl,
  Label,
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

export const ProposalList: FC = observer(() => {
  const [selectedOption, setSelectedOption] = useState("All");
  const navigate = useNavigate();
  const urlParams = useParams();
  const { store } = useMst();
  const currentBoothName = getNameFromUrl(urlParams);
  const currentBoothKey = getKeyFromUrl(urlParams);
  let leftPane;

  // leftPane = useMemo(() => {
  const booth = store.booth;
  let proposalsList: any[] = booth?.listProposals!;

  const hasAdmin = booth?.hasAdmin;
  const statusCounts = getProposalFilters(proposalsList);
  if (selectedOption === "All") {
    proposalsList = proposalsList;
  } else {
    proposalsList = proposalsList.filter(
      (proposal: ProposalType) => proposal.status === selectedOption
    );
  }

  const options = [
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
  ];
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
        subtitle={{ patp: true, text: currentBoothName }}
        options={options}
        selectedOption={selectedOption}
        rightContent={
          // @ts-ignore
          hasAdmin && (
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
          <Flex style={{ width: 220 }} justifyContent="flex-end" itemsCenter>
            <Label style={{ width: 100 }}>Sort by</Label>
            <Select
              small
              selectionOption={booth!.sortBy}
              options={[
                {
                  label: "Recent",
                  value: "recent",
                },
                {
                  label: "Ending soon",
                  value: "ending",
                },
                {
                  label: "Starting soon",
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
      {proposalsList?.length ? (
        <VirtualizedList
          id={`list-${currentBoothKey}-${new Date().getMilliseconds()}`}
          style={{
            marginTop: 12,
            height: "calc(100% - 12px)",
          }}
          itemHeight={112}
          numItems={proposalsList.length}
          renderItem={({
            key,
            index,
            style,
          }: {
            key: number;
            index: number;
            style: any;
          }) => {
            const proposal: ProposalModelType = proposalsList[index];
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
                  {
                    label: "Edit",
                    disabled:
                      proposal.status === "Active" ||
                      proposal.status === "Ended" ||
                      !hasAdmin,
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
                      !hasAdmin ||
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
    </Flex>
  );
  // }, [currentBooth, booth?.proposals, selectedOption]);

  const participants = booth ? booth.listParticipants : [];
  const participantLoading = booth ? booth.participantStore.isLoading : false;
  return (
    <Grid2.Box offset={40} fluid scroll>
      <Grid2.Box>
        <Grid2.Column mt="16px" lg={12} xl={12}>
          <Grid2.Row justify="center">
            <Grid2.Column xs={4} sm={5} md={5} lg={9} xl={9}>
              {leftPane}
            </Grid2.Column>
            <Grid2.Column xs={4} sm={3} md={3} lg={3}>
              <Participants
                loading={participantLoading}
                participants={[
                  ...participants,
                  // {
                  //   created: "1648727455199",
                  //   key: "~dev",
                  //   metadata: { color: "#365" },
                  //   name: "~dev",
                  //   status: "active",
                  // },
                  // {
                  //   created: "1648727455199",
                  //   key: "~mul",
                  //   metadata: { color: "#779" },
                  //   name: "~mul",
                  //   status: "active",
                  // },
                  // {
                  //   created: "1648727455199",
                  //   key: "~lux",
                  //   metadata: { color: "#861" },
                  //   name: "~lux",
                  //   status: "active",
                  // },
                  // {
                  //   created: "1648727455199",
                  //   key: "~rib",
                  //   metadata: { color: "#026" },
                  //   name: "~rib",
                  //   status: "active",
                  // },
                  // {
                  //   created: "1648727455199",
                  //   key: "~hal",
                  //   metadata: { color: "#311" },
                  //   name: "~hal",
                  //   status: "active",
                  // },
                  // {
                  //   created: "1648727455199",
                  //   key: "~dib",
                  //   metadata: { color: "#0a9e11" },
                  //   name: "~dib",
                  //   status: "active",
                  // },
                  // {
                  //   created: "1648727455199",
                  //   key: "~hocnus",
                  //   metadata: { color: "#311" },
                  //   name: "~hocnus",
                  //   status: "active",
                  // },
                  // {
                  //   created: "1648727455199",
                  //   key: "~dovnus",
                  //   metadata: { color: "#9e4500" },
                  //   name: "~dovnus",
                  //   status: "active",
                  // },
                  // {
                  //   created: "1648727455199",
                  //   key: "~sap",
                  //   metadata: { color: "#000" },
                  //   name: "~sap",
                  //   status: "active",
                  // },
                ]}
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
