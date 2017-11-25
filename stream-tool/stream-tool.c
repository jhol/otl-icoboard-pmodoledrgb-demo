/*
 * Copyright (c) 2017 Joel Holdsworth <joel@airwebreathe.org.uk>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <fcntl.h>
#include <linux/spi/spidev.h>
#include <linux/types.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
  (void)argc;
  (void)argv;

  const size_t buffer_size = 96 * 64 * 2;
  const char *device = "/dev/spidev0.1";
  const uint8_t mode = 0;
  const uint8_t bits = 8;
  const uint32_t speed = 15600000;
  const size_t max_transfer_size = 4096;

  uint8_t buffer[buffer_size];
  size_t offset;

  const int spi_fd = open(device, O_RDWR);
  if (spi_fd < 0) {
    perror("Failed to open device");
    return EXIT_FAILURE;
  }

  if (ioctl(spi_fd, SPI_IOC_WR_MODE, &mode) == -1 ||
    ioctl(spi_fd, SPI_IOC_WR_BITS_PER_WORD, &bits) == -1 ||
    ioctl(spi_fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed) == -1) {
    perror("Failed to configure SPI port");
    close(spi_fd);
    return EXIT_FAILURE;
  }

  while (fread(buffer, 1, buffer_size, stdin) == buffer_size) {
    offset = 0;
    while (offset < buffer_size) {
      const size_t bytes_remain = buffer_size - offset;
      const bool last_transfer = bytes_remain <= max_transfer_size;
      const size_t transfer_size = last_transfer ?
	bytes_remain : max_transfer_size;
      if (ioctl(spi_fd, SPI_IOC_MESSAGE(1),
	&(struct spi_ioc_transfer){
          .tx_buf = (unsigned long)buffer + offset,
          .rx_buf = (unsigned long)NULL,
          .len = transfer_size,
          .cs_change = last_transfer ? 0 : 1,
          .delay_usecs = last_transfer ? 1 : 0,
          .speed_hz = speed,
          .bits_per_word = bits,
        }) < 1) {
        perror("Failed to send message");
        close(spi_fd);
        return EXIT_FAILURE;
      }
      offset += transfer_size;
    }
  }

  close(spi_fd);

  return EXIT_SUCCESS;
}
