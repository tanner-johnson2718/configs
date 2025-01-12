#include "test.h"

struct bcmgenet_priv {
	void __iomem *base;
	enum bcmgenet_version version;
	struct net_device *dev;

	/* transmit variables */
	void __iomem *tx_bds;
	struct enet_cb *tx_cbs;
	unsigned int num_tx_bds;

	struct bcmgenet_tx_ring tx_rings[DESC_INDEX + 1];

	/* receive variables */
	void __iomem *rx_bds;
	struct enet_cb *rx_cbs;
	unsigned int num_rx_bds;
	unsigned int rx_buf_len;
	struct bcmgenet_rxnfc_rule rxnfc_rules[MAX_NUM_OF_FS_RULES];
	struct list_head rxnfc_list;

	struct bcmgenet_rx_ring rx_rings[DESC_INDEX + 1];

	/* other misc variables */
	struct bcmgenet_hw_params *hw_params;

	/* MDIO bus variables */
	wait_queue_head_t wq;
	bool internal_phy;
	struct device_node *phy_dn;
	struct device_node *mdio_dn;
	struct mii_bus *mii_bus;
	u16 gphy_rev;
	struct clk *clk_eee;
	bool clk_eee_enabled;

	/* PHY device variables */
	int old_link;
	int old_speed;
	int old_duplex;
	int old_pause;
	phy_interface_t phy_interface;
	int phy_addr;
	int ext_phy;

	/* Interrupt variables */
	struct work_struct bcmgenet_irq_work;
	int irq0;
	int irq1;
	int wol_irq;
	bool wol_irq_disabled;

	/* shared status */
	spinlock_t lock;
	unsigned int irq0_stat;

	/* HW descriptors/checksum variables */
	bool crc_fwd_en;

	u32 dma_max_burst_length;

	u32 msg_enable;

	struct clk *clk;
	struct platform_device *pdev;
	struct platform_device *mii_pdev;

	/* WOL */
	struct clk *clk_wol;
	u32 wolopts;
	u8 sopass[SOPASS_MAX];
	bool wol_active;

	struct bcmgenet_mib_counters mib;

	struct ethtool_eee eee;
};
